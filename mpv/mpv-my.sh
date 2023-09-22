#!/bin/bash
url="$1"
bili="bilibili"
a=${url%.com*}
web=${a#*.}
if [ "$web" = "$bili" ]; then
	{
		echo "open-bilibili"
		echo "进入临时目录"
		pushd /home/kdk/.config/mpv/danmu || exit 1

		bili_url=${url%/*}

		urls=$(yt-dlp --get-url "$bili_url")
		video_url=$(echo "$urls" | head -n 1)
		audio_url=$(echo "$urls" | tail -n 1)

		#download+convert danmaku file
		echo "开始下载弹幕"
		xml_path_list=$(yt-dlp "$bili_url" --write-subs --skip-download  --trim-filenames 10  | grep "Writing video subtitles" | sed "s|\[info\] Writing video subtitles to: |$PWD/|g")
    xml_path=$(echo "$xml_path_list" | head -n 1)
    
		ass_path="${xml_path/xml/ass}"

		medianame_1=${ass_path##*/}
		medianame=${medianame_1%.*}

		echo "转换弹幕"
		danmaku2ass "$xml_path" \
			-o "$ass_path" \
			-s "3840x2160" \
			-fn "SourceHanSansCN-Regular" \
			-fs 70 -a 0.8 -p 270 -dm 10

		rm -rfv "$xml_path"

		popd || exit 1

		echo "开始播放"
		mpv  "$video_url" \
			--audio-file="$audio_url" \
			--sub-file="$ass_path" \
			--referrer="https://www.bilibili.com" \
			--no-ytdl \
			--force-media-title="$medianame"
	}
else
	{
		echo "other"
		mpv "$url"
	}
fi
