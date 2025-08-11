#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/sops-add-secret.sh [path/to/secrets.yaml]
# - Prompts for a secret path (e.g. tailscale/hskey.txt)
# - Prompts for the secret value (hidden)
# - Ensures nested YAML keys for sops-nix (tailscale: { hskey.txt: ... })
# - If the secrets file is not initialized, prompts for Age recipients and initializes encryption

secrets_file="${1:-./secrets.yaml}"

read -rp "Secret name (e.g. tailscale/hskey.txt): " secret_path
if [[ -z "${secret_path}" ]]; then
  echo "Error: secret name is required" >&2
  exit 1
fi

read -srp "Secret value (input hidden): " secret_value
echo
if [[ -z "${secret_value}" ]]; then
  echo "Error: secret value is required" >&2
  exit 1
fi

# Build the JSON path selector for sops --set, e.g. ["tailscale"]["hskey.txt"]
IFS='/' read -r -a parts <<<"${secret_path}"
if (( ${#parts[@]} == 0 )); then
  echo "Error: invalid secret path" >&2
  exit 1
fi
json_path=""
for p in "${parts[@]}"; do
  # escape quotes in key names
  p_escaped=${p//\"/\\\"}
  json_path+="[\"${p_escaped}\"]"
done

# Determine if the file appears to be initialized as a sops file (has a sops: stanza)
needs_init=1
if [[ -f "${secrets_file}" ]] && grep -qE '^sops:' "${secrets_file}"; then
  needs_init=0
fi

if (( needs_init == 0 )); then
  # File already initialized; just set the value
  sops --set "${json_path}" "${secret_value}" -i "${secrets_file}"
else
  echo "Initializing ${secrets_file} with Age recipients for encryption..."
  read -rp "Age recipient(s) (comma-separated, e.g. age1...,age1...): " recipients
  if [[ -z "${recipients}" ]]; then
    echo "Error: at least one Age recipient is required to initialize" >&2
    exit 1
  fi

  # Create a temporary plaintext YAML with the nested keys
  tmp_file=$(mktemp)
  # Build nested YAML structure by indentation
  for (( i=0; i<${#parts[@]}; i++ )); do
    key="${parts[$i]}"
    indent=$(printf '%*s' $((i*2)) '')
    if (( i == ${#parts[@]} - 1 )); then
      printf '%s%s: "%s"\n' "${indent}" "${key}" "${secret_value}" >> "${tmp_file}"
    else
      printf '%s%s:\n' "${indent}" "${key}" >> "${tmp_file}"
    fi
  done

  # Build --age flags
  IFS=',' read -r -a recs <<<"${recipients}"
  args=()
  for r in "${recs[@]}"; do
    trimmed=$(echo "${r}" | xargs)
    [[ -n "${trimmed}" ]] && args+=(--age "${trimmed}")
  done
  if (( ${#args[@]} == 0 )); then
    echo "Error: no valid Age recipients provided" >&2
    rm -f "${tmp_file}"
    exit 1
  fi

  # Encrypt in place and move to target path
  sops "${args[@]}" --encrypt --in-place "${tmp_file}"
  mv "${tmp_file}" "${secrets_file}"
fi

echo "Done. Secret '${secret_path}' stored in ${secrets_file}"