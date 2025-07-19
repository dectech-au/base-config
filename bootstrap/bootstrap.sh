#!/usr/bin/env bash
#~/.dotfiles/update-personal-tim.sh
(
	set -euo pipefail

	CURRENT_GEN=$(nixos-rebuild list-generations | awk '/current/ {print $1}')

	if [[ "$CURRENT_GEN" -eq 1 ]]; then
		echo "First generation detected. Bootstrapping system configuration..."
		sudo mkdir -p /mnt
		sudo mount /dev/disk/by-partlabel/dectech /mnt
		sudo cp /mnt/home/dectec/.dotfiles/bootstrap/bootstrap-configuration.nix /etc/nixos/configuration.nix
		sudo nixos-rebuild switch
  
		SSH_KEY="$HOME/.ssh/id_nixos_readonly" # SSH key setup
		if [[ ! -f "$SSH_KEY" ]]; then
			echo "Generating SSH key for read-only Git access..."
			ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "nixos-readonly"

			GITHUB_TOKEN=$(tr -d '\n' < /mnt/home/dectec/.dotfiles/bootstrap/github-token.txt)
			GITHUB_USER="dectech-au"
			GITHUB_REPO="base-config"

			echo "Uploading SSH key to GitHub repo '$GITHUB_USER/$GITHUB_REPO'..."

			HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/deploykey-response.txt \
				-H "Authorization: token $GITHUB_TOKEN" \
				-H "Accept: application/vnd.github.v3+json" \
				https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/keys \
-d @- <<EOF
{
					"title": "nixos-$(hostname)-$(date +%s)",
					"key": "$(cat "${SSH_KEY}.pub")",
					"read_only": true
				}
EOF
			)


			if [[ "$HTTP_CODE" -ne 201 ]]; then
				echo "Failed to add deploy key. GitHub API responded with $HTTP_CODE"
				cat /tmp/deploykey-response.txt
				exit 1
				else
				echo "SSH key successfully added as a deploy key."
			fi

			else
			echo "SSH key already exists. Skipping generation."
		fi
	
		unset GITHUB_TOKEN
		echo "preserving hardware-configuration.nix..."
		TEMP_HW=$(mktemp)
		sudo cp /etc/nixos/hardware-configuration.nix "$TEMP_HW"

		echo "Cloning flake repo into /etc/nixos/..."
		sudo rm -rf /etc/nixos
		sudo mkdir -p /etc/nixos
		sudo chown "${USER}" /etc/nixos
  
		GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" git clone git@github.com:dectech-au/base-config.git /etc/nixos

		echo "Restoring hardware-configuration.nix"
		sudo cp "$TEMP_HW" /etc/nixos/hardware-configuration.nix
		sudo chown root:root /etc/nixos/hardware-configuration.nix
		rm "$TEMP_HW"

		sudo chown -R root:root /etc/nixos
	fi
	

	STAMP_FILE="/tmp/nix_flake_update.timestamp" # Define timestamp file

	# Check if the file exists and if it's less than 10 minutes old
	if [[ ! -f "$STAMP_FILE" || $(($(date +%s) - $(< "$STAMP_FILE"))) -ge 600 ]]; then
		echo "Running nix flake update..."
		nix flake update
		date +%s > "$STAMP_FILE"
	else
		echo "Skipping nix flake update (ran recently)."
	fi

	SERIAL=$(sudo cat /sys/class/dmi/id/product_serial | tr -d ' ')
	[[ -z "$SERIAL" || "$SERIAL" == "Unknown" ]] && SERIAL=$(cat /etc/machine-id | cut -c1-8)


  HOSTNAME="dectech-${SERIAL: -6}"
  echo "$HOSTNAME" | sudo tee /etc/nixos/system-hostname.txt >/dev/null
  sudo nixos-rebuild switch --upgrade --flake /etc/nixos#enterprise-base


	echo "Done!"
	sleep 2  # short pause before closing
) && exit
