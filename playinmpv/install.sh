#! /bin/bash
if command -v xdg-open >/dev/null 2>&1; then 
  echo 'exists xdg-open' 
else 
  echo 'no exists xdg-open, please install it' 
  exit
fi
if command -v mpv >/dev/null 2>&1; then 
  echo 'exists mpv' 
else 
  echo 'no exists mpv, please install it'
  exit
fi
#sudo cp playinmpv /usr/local/bin/playinmpv
#sudo chmod +x /usr/local/bin/playinmpv
#cp playinmpv.desktop ~/.local/share/applications/ -r
SCRIPTPATH=$(cd $(dirname $(readlink -f "${BASH_SOURCE[0]}")) && pwd )
BINPATH="$SCRIPTPATH/playinmpv"
chmod +x $BINPATH 
#echo $BINPATH 
echo -e "\nx-scheme-handler/mpv=playinmpv.desktop" >> ~/.local/share/applications/mimeapps.list
echo "[Desktop Entry]
Type=Application
Name=playinmpv
Comment=Play Bilibili videos with MPV
NoDisplay=true
Exec=$BINPATH %U
MimeType=x-scheme-handler/mpv;
" >> ~/.local/share/applications/playinmpv.desktop
