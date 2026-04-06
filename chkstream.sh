#!/bin/bash

# Входные параметры
m3u8_url="$1"
output_file="sd_streams.m3u8"

# Проверяем наличие аргументов
if [[ -z "$m3u8_url" ]]; then
    echo "Использование: $0 <URL_M3U8>"
    exit 1
fi

# Создаём временный файл для SD-потоков
> "$output_file"

# Читаем файл построчно
while IFS= read -r line; do
    # Убираем пробелы по краям
    line=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    # Если строка пустая — пропускаем
    [[ -z "$line" ]] && continue

    # Сохраняем строку #EXTINF
    if [[ "$line" == "#EXTINF"* ]]; then
        extinf_line="$line"
        continue
    fi

    # Сохраняем строку #EXTGRP
    if [[ "$line" == "#EXTGRP"* ]]; then
        extgrp_line="$line"
        continue
    fi

    # Если строка начинается с http — это URL потока
    if [[ "$line" == http* ]]; then
        stream_url="$line"

        echo "Проверяем поток: $stream_url"

        # Получаем информацию о разрешении через ffprobe
        json_info=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of json "$stream_url")

        # Извлекаем ширину и высоту
        if command -v jq &> /dev/null; then
            width=$(echo "$json_info" | jq -r '.streams[0].width // "0"')
            height=$(echo "$json_info" | jq -r '.streams[0].height // "0"')
        else
            # Альтернатива без jq
            width=$(echo "$json_info" | grep -o '"width": [0-9]*' | sed 's/"width": //' || echo "0")
            height=$(echo "$json_info" | grep -o '"height": [0-9]*' | sed 's/"height": //' || echo "0")
        fi

        # Проверяем, является ли поток валидным (ширина и высота > 0) и SD (до 720×576)
        if [[ $width -gt 0 ]] && [[ $height -gt 0 ]] && [[ $width -le 1024 ]] && [[ $height -le 856 ]]; then
            echo "Найден SD поток: ${stream_url} (${width}x${height})"
            # Записываем заголовок M3U8 только один раз в начале
            if [[ ! -s "$output_file" ]]; then
                echo "#EXTM3U" >> "$output_file"
            fi
            # Записываем метаданные и URL в выходной файл
            echo "$extinf_line" >> "$output_file"
            echo "$extgrp_line" >> "$output_file"
            echo "$stream_url" >> "$output_file"
        else
            if [[ $width -eq 0 ]] || [[ $height -eq 0 ]]; then
                echo "Поток невалиден: разрешение ${width}x${height}"
            else
                echo "Поток не SD: ${width}x${height}"
            fi
        fi

        # Сбрасываем метаданные для следующего блока
        extinf_line=""
        extgrp_line=""
    fi
done < "$m3u8_url"

echo "Готово! SD-потоки сохранены в: $output_file"
