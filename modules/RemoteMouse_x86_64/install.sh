#! /bin/sh

# Check if running on Ubuntu
if command -v apt-get &> /dev/null; then
  echo "Updating package manager on Ubuntu"
  sudo apt-get update
  echo "Installing must-have pre-requisites on Ubuntu"
  sudo apt-get install xclip -y
  sudo apt install --reinstall libxcb-xinerama0 -y

# Check if running on Arch Linux
elif command -v pacman &> /dev/null; then
  echo "Updating package manager on Arch Linux"
  sudo pacman -Sy
  echo "Installing must-have pre-requisites on Arch Linux"
  sudo pacman -S xclip

# If running on neither, show error message
else
  echo "Error: this script is only compatible with Ubuntu, Arch Linux, and CentOS"
  exit 1
fi
