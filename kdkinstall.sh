#!/bin/bash

bak_path="/mnt/backup"
kdk_home="/home/kdk"

echo "bak_path=$bak_path,kdk_home=$kdk_home"
while true; do
	echo -e "
1.backup
2.systeminstall-1 (liveiso)
3.systeminstall-2 (chroot)
4.systeminstall-3 (native root firststart)
5.systeminstall-4 (native kdk install application)
6.after
"

	read -p "请输入你的选择:(1-5)" char

	case $char in

	1)
		#备份
		pushd "$bak_path" || exit

		echo "清理备份"
		sudo rm -rf ./* && sudo rm -rf .[^.] .??* || echo "清除备份失败,或没有可以清理的"

		popd || exit
		sudo mkdir -pv "$bak_path"/.config && sudo chown kdk:kdk "$bak_path"/.config && sudo cp -apr "$kdk_home"/.config/{aria2,cava,fcitx5,jellyfin.org,kitty,mpv,mvi,qBittorrent,sway,systemd,waybar,wofi,yt-dlp} "$bak_path"/.config && sudo cp -apr "$kdk_home"/{.emacs.d,.spacemacs,.zshrc,.Xresources} "$bak_path" && sudo cp -apr "$kdk_home"/Desktop/autobangumi "$bak_path" && sudo cp -apr /etc/{environment,fstab} "$bak_path" && sudo cp -apr /var/lib/jellyfin "$bak_path" && sudo cp -apr "$kdk_home"/.mozilla "$bak_path" && sudo cp -apr /usr/share/wayland-sessions/sway.desktop "$bak_path"

		;;

	2)
		#系统安装-1

		echo "更新系统时钟"
		timedatectl

		echo "开始分区"
		echo "清楚磁盘分区"
		sfdisk --delete /dev/nvme0n1 || exit

		echo "分区"
		echo -e ',300M,U\n,8G,S\n,+,L\n' | sfdisk /dev/nvme0n1 || exit

		echo "格式化分区"
		mkfs.ext4 /dev/nvme0n1p3
		mkswap /dev/nvme0n1p2
		mkfs.fat -F 32 /dev/nvme0n1p1

		echo "挂载分区"
		mount /dev/nvme0n1p3 /mnt && mkdir /mnt/boot && mount /dev/nvme0n1p1 /mnt/boot && swapon /dev/nvme0n1p2 || exit

		echo "安装基本软件"
		pacstrap -K /mnt base linux linux-firmware intel-ucode networkmanager nano man man-pages-zh_cn

		genfstab -U /mnt >>/mnt/etc/fstab

		echo "结束安装第一阶段，请输入 arch-chroot /mnt  进入chroot"
		;;

	3)

		#系统安装-2 chroot
		echo "设置时区"
		ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && hwclock --systohc || exit

		echo "设置语言
"
		echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen && echo "zh_CN.UTF-8 UTF-8" >>/etc/locale.gen && locale-gen || exit

		echo "设置主机名"
		touch /etc/hostname && echo "arch@kdk" >>/etc/hostname || exit

		echo "设置root密码"
		passwd

		echo "安装grub"
		pacman -Syu && pacman -S grub efibootmgr && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB && grub-mkconfig -o /boot/grub/grub.cfg || exit

		echo "系统安装完成，重启进入新系统"
		;;

	4)
		#刚安装完成
		echo "启动网络"
		systemctl enable NetworkManager.service
		systemctl start NetworkManager.service

		echo "创建用户kdk"
		useradd -m kdk && passwd kdk || exit

		mkdir "$kdk_home"/data && chmod -R kdk:kdk "$kdk_home"/data

		pacman -Syu && pacman -S sudo && EDITOR=nano visudo || exit

		mkdir -pv "$bak_path"

		mount /dev/sda3 "$bak_path"

		echo "QT_QPA_PLATFORM=wayland
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx

GLFW_IM_MODULE=ibus

MOZ_ENABLE_WAYLAND=1" >>/etc/environment

		cat "/dev/sda1					/home/kdk/data         ntfs3     defaults,uid=1000,gid=1000   0  0" >>/etc/fstab

		umount "$bak_path"

		echo "you need reboot"
		;;

	5)
		#安装后 kdk
		mkdir -pv tmp
		cd tmp || exit 1

		sudo pacman -Syu

		sudo mount /dev/sda3 "$bak_path"

		cp -arpv "$bak_path"/{.Xresources,.zshrc} "$kdk_home"

		#yay
		sudo pacman -S --needed git base-devel
		git clone https://aur.archlinux.org/yay.git
		pushd yay || exit
		makepkg -si

		popd || exit 2

		#先把软件安装了

		echo "安装pacman软件"
		sudo pacman -S kitty fcitx5 fcitx5-chinese-addons fcitx5-configtool \
			   fcitx5-gtk fcitx5-qt adobe-source-code-pro-fonts adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts adobe-source-han-serif-otc-fonts awesome-terminal-fonts cantarell-fonts noto-fonts noto-fonts-cjk powerline-fonts ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-ubuntu-nerd wqy-microhei wqy-microhei-lite wqy-bitmapfont wqy-zenhei ttf-arphic-ukai ttf-arphic-uming dunst wireplumber pipewire-audio pipewire-jack pipewire-pulse pipewire-alsa pipewire-v4l2 pavucontrol helvum glfw-wayland qt5-wayland qt6-wayland vulkan-validation-layers wofi kdeconnect bluez blueman mpv mpv-mpris yt-dlp docker docker-compose aria2 zsh openssh mosh wget cmake emacs ripgrep libvterm pandoc npm clang bash-language-server shellcheck shfmt mesa vulkan-intel intel-media-driver libva-utils onevpl-intel-gpu intel-compute-runtime firefox vlc vim network-manager-applet sddm polkit lxqt-policykit intel-gpu-tools htop yad xdg-desktop-portal xdg-desktop-portal-wlr  || exit

		echo "yay"
		yay -Scc && yay -S wlroots-git && yay -S sway-git && yay -S swaybg-git && yay -S cava && yay -S waybar-cava waybar-module-pacman-updates-git autotiling wob danmaku2ass-git qbittorrent-enhanced-nox jellyfin jellyfin-ffmpeg6-bin cmake-language-server clipman || exit

		echo "安装npm软件"
		sudo npm install -g vmd || exit

		echo "sddm"
		sudo systemctl enable sddm

		#sway
		echo "sway"
		sudo cp -aprv "$bak_path"/sway.desktop /usr/share/wayland-sessions
		sudo cp -aprv "$bak_path"/.config/sway "$kdk_home"/.config || exit

		#waybar

		echo "waybar"
		sudo cp -apr "$bak_path"/.config/waybar "$kdk_home"/.config && sudo cp -apr "$bak_path"/.config/cava "$kdk_home"/.config || exit

		#kitty

		echo "kitty"
		sudo cp -apr "$bak_path"/.config/kitty "$kdk_home"/.config || exit

		#fcitx
		echo "fcitx"
		sudo cp -apr "$bak_path"/.config/fcitx5 "$kdk_home"/.config || exit

		#wofi
		echo "wofi"
		sudo cp -apr "$bak_path"/.config/wofi "$kdk_home"/.config || exit

		#bluetooth
		echo "bluetooth systemctl"
		sudo systemctl start bluetooth && sudo systemctl enable bluetooth || exit

		pushd /lib/firmware/intel || exit
		echo $PWD
		sudo ln -vs ibt-1040-4150.ddc.zst ibt-0040-1050.ddc.zst
		sudo ln -vs ibt-1040-4150.sfi.zst ibt-0040-1050.sfi.zst
		popd || exit

		#mpv
		echo "mpv"
		sudo cp -apr "$bak_path"/.config/mpv "$kdk_home"/.config && sudo cp -apr "$bak_path"/.config/yt-dlp "$kdk_home"/.config && sudo cp -apr "$bak_path"/.config/mvi "$kdk_home"/.config || exit

		#qbittorrent
		echo "qbittorrent"
		sudo cp -apr "$bak_path"/.config/qBittorrent "$kdk_home"/.config || exit

		sudo systemctl start qbittorrent-nox@kdk && sudo systemctl enable qbittorrent-nox@kdk || exit

		### docker
		echo "docker"
		sudo systemctl start docker && sudo systemctl enable docker
		mkdir -pv vackup
		pushd vackup || exit

		sudo cp -apr "$bak_path"/autobangumi "$kdk_home"
		pushd "$kdk_home"/autobangumi || exit
		sudo docker-compose up -d || echo "docker-compose up -d wrong" || exit
		echo "success start autobangumi"

		popd || exit

		wget https://raw.githubusercontent.com/BretFisher/docker-vackup/main/vackup || exit
		#恢复备份
		echo "恢复备份"
		chmod +x vackup
		#sudo ./vackup import AutoBangumi_config_bak.tar.gz AutoBangumi_config && sudo ./vackup import "$bak_path"/AutoBangumi_data_bak.tar.gz AutoBangumi_data || exit

		pushd "$kdk_home"/autobangumi || exit
		echo "重启容器"
		sudo docker-compose restart
		popd || exit

		popd || exit

		### aria2
		echo "aria2恢复"
		sudo cp -apr "$bak_path"/.config/aria2 "$kdk_home"/.config || exit

		echo "systemd user service"
		sudo cp -apr "$bak_path"/.config/systemd "$kdk_home"/.config || exit

		echo "systemctl --user start aria2cd.service"
		systemctl --user enable aria2cd.service || exit

		### emacs
		echo "emacs恢复"
		sudo cp -apr "$bak_path"/.emacs.d "$kdk_home" && sudo cp -apr "$bak_path"/.spacemacs "$kdk_home" || exit
		#systemctl --user start emacs.service
		#systemctl --user enable  emacs.service

		echo "firefox"
		sudo cp -apr "$bak_path"/.mozilla "$kdk_home"

		#jellyfin
		echo "jellyfin 恢复"
		#sudo cp -apr "$bak_path"/.config/jellyfin.org "$kdk_home"/.config && sudo cp -apr "$bak_path"/jellyfin /var/lib || exit

		#echo "启动服务"
		#sudo systemctl start jellyfin && sudo systemctl enable jellyfin || exit

		echo "jellyfin加入render组"
		sudo usermod -aG render jellyfin || exit

		echo "重启jellyfin"
		## sudo systemctl restart jellyfin || exit

		;;

	6)
		exit

		;;
	*)
		exit
		;;
	esac

done

## shell 最好最好弄 可能会改变bash环境
# sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# cp -apr "$bak_path"/.zshrc  "$kdk_home"
# source "$kdk_home"/.zshrc
