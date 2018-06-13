#!/bin/bash

fade_duration=1 # seconds
filesuffix=".mov"

if [[ ! $4 ]]; then
    cat<<EOF
Usage:
    ${0##*/} <input mp4> <output mp4> <start time in seconds> <end time in seconds>
EOF
    exit 1
fi

for x in bc awk ffprobe ffmpeg; do
    if ! type &>/dev/null $x; then
        echo >&2 "$x should be installed"
        ((err++))
    fi
done

((err > 0)) && exit 1

duration=$(ffprobe -select_streams v -show_streams "$1" 2>/dev/null |
    awk -F= '$1 == "duration"{print $2}')
final_cut=$(bc -l <<< "$4 - $fade_duration")
start_cut=$(bc -l <<< "$3")
ffmpeg -i "$1" \
    -ac 1 \
    -ss $3 -to $4 \
    -filter:v "fade=out:st=$final_cut:d=$fade_duration, fade=in:st=$start_cut:d=$fade_duration" \
    -af "afade=t=out:st=$final_cut:d=$fade_duration, afade=t=in:st=$start_cut:d=$fade_duration" \
    -c:v libx264 -crf 22 -preset veryfast -strict -2 "$2$filesuffix"
