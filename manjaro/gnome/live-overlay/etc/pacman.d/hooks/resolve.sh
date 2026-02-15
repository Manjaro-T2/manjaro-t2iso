sudo echo "IgnorePkg = wpa_supplicant" >>/etc/pacman.conf
sudo mv wpahook block-wpa-upgrade.hook
sudo pacman -Sy
