#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/sops-add-secret.sh [path/to/secrets.yaml]
# - Prompts for a secret path (e.g. tailscale/hskey.txt)
# - Prompts for the secret value (hidden)
# - Ensures nested YAML keys for sops-nix (tailscale: { hskey.txt: ... })
# - Assumes Age key file is at /root/.config/sops/age/keys.txt
# - Initializes and encrypts with sops automatically (no recipient prompt)

secrets_file="${1:-./secrets.yaml}"

# Assume this Age key file; let user override via env if they want
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-/root/.config/sops/age/keys.txt}"

if [[ ! -f "${SOPS_AGE_KEY_FILE}" ]]; then
  echo "Error: Age key file not found at ${SOPS_AGE_KEY_FILE}" >&2
  echo "Generate it with: mkdir -p \"$(dirname \"${SOPS_AGE_KEY_FILE}\")\" && age-keygen -o \"${SOPS_AGE_KEY_FILE}\"" >&2
  exit 1
fi

# Derive recipient (public key) from the private key file
recipient=$(age-keygen -y "${SOPS_AGE_KEY_FILE}" 2>/dev/null || true)
if [[ -z "${recipient}" ]]; then
  echo "Error: Failed to derive Age recipient from ${SOPS_AGE_KEY_FILE}" >&2
  exit 1
fi

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
  p_escaped=${p//\"/\\\"}
  json_path+="[\"${p_escaped}\"]"
done

# Determine if the file appears to be initialized as a sops file (has a sops: stanza)
needs_init=1
if [[ -f "${secrets_file}" ]] && grep -qE '^[[:space:]]*sops:' "${secrets_file}"; then
  needs_init=0
fi

if (( needs_init == 0 )); then
  # File already initialized; just set the value using our private key
  sops --set "${json_path}" "${secret_value}" -i "${secrets_file}"
else
  # Initialize: create a temporary plaintext YAML with the nested keys and encrypt with our derived recipient
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

  # Encrypt in place and move to target path
  sops --age "${recipient}" --encrypt --in-place "${tmp_file}"
  mv "${tmp_file}" "${secrets_file}"
fi

echo "Done. Secret '${secret_path}' stored in ${secrets_file}"