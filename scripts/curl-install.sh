#!/bin/bash

# Checking if is running in Repo Folder
if [[ "$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]')" =~ ^scripts$ ]]; then
    echo "You are running this in ArchTitus Folder."
    echo "Please use ./archtitus.sh instead"
    exit
fi

# Installing git

echo "Installing git."
pacman -S --noconfirm --needed git glibc

echo "Cloning the ArchTitus Project"
git clone https://github.com/Rust1667/ArchTitus

echo "Executing ArchTitus Script"

cd $HOME/ArchTitus

exec ./archtitus.sh
