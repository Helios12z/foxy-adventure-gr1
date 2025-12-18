#!/bin/bash
# Script để convert các file audio lớn sang OGG với chất lượng thấp hơn

# Yêu cầu: Cài đặt ffmpeg
# Windows: choco install ffmpeg
# Mac: brew install ffmpeg

# Convert MP3 to OGG with lower quality
find asset/sounds -name "*.mp3" -size +3M -exec sh -c '
    for file; do
        output="${file%.mp3}.ogg"
        if [ ! -f "$output" ]; then
            ffmpeg -i "$file" -c:a libvorbis -q:a 4 "$output"
            echo "Converted: $file -> $output"
        fi
    done
' sh {} +

echo "Done! Remember to update references in Godot"
