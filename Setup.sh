#!/bin/bash

RED='\033[0;31m';
NC='\033[0m'; # No Color
GREEN='\033[0;32m';
YELLOW='\033[1;33m';

CWD=`pwd`;

delay_after_message=3;

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run with sudo (sudo -i)" 
   exit 1
fi

read -p "Please enter your username: " target_user;

if id -u "$target_user" >/dev/null 2>&1; then
    echo "User $target_user exists! Proceeding.. ";
else
    echo 'The username you entered does not seem to exist.';
    exit 1;
fi

# Function to run as a non-root user
run_as_user() {
	sudo -u $target_user bash -c "$1";
}

apt update
apt upgrade
apt install curl -y

# Remove Firefox snap and set up apt repository for firefox.
printf "${YELLOW}Removing Firefox snap and setting up Firefox apt repository${NC}\n"
sleep $delay_after_message;
snap remove firefox
install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

# Adds the 1password apt Repository
printf "${YELLOW} Adding the 1password apt Repository${NC}\n"
sleep $delay_after_message;
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# Adds the Cloudflare Warp Repositories
printf "${YELLOW} Adding the Cloudflare Warp Repositories apt Repository${NC}\n"
sleep $delay_after_message;
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# Adds the Spotify APT Repository
printf "${YELLOW} Adding the Spotify apt Repository${NC}\n"
sleep $delay_after_message;
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list


printf "${YELLOW} Updating APT and installing packages${NC}\n"
sleep $delay_after_message;
apt update
for i in $(cat APT_PACKAGE_LIST);
    do 
    printf "${YELLOW} Installing $i${NC}"
    sudo apt install $i -y;
done

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.prismlauncher.PrismLauncher -y
flatpak install flathub com.discordapp.Discord -y
flatpak install flathub tv.plex.PlexDesktop -y
flatpak install flathub com.jetbrains.IntelliJ-IDEA-Community -y
flatpak install flathub org.gnome.Shotwell -y

printf "${YELLOW} Installing Oh My ZSH${NC}"
cd /home/$target_user/
git clone https://github.com/xaniel123/.dotfiles.git
cd /home/$target_user/.dotfiles/
cp /home/$target_user/.dotfiles/zshenv /etc/zsh/
run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv /home/$target_user/.oh-my-zsh /home/$target_user/.dotfiles/zsh
rm /home/$target_user/.zshrc

printf "${Yellow} Installing Walpapers${NC}"
cd /home/$target_user/Pictures
run_as_user git clone https://github.com/xaniel123/AnimeWallpapers.git


printf "${Yellow} Configuring Cloudflare Zero Trust${NC}"
run_as_user warp-cli teams-enroll poisonfajita

