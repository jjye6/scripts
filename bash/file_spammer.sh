#!/bin/bash

# Number of files
file_num=5

# Folder path
folder_path="."

# Random file name generator
function name_generator {
    length=10
    carac=abcdefghijklmnopqrstuvwxyz0123456789
    name=$(cat /dev/urandom | tr -dc "$carac" | fold -w "$length" | head -n 1)
    echo "$name"
}

# File creation
for i in $(seq 1 $file_num); do
    name=$(name_generator)
    path="$folder_path/$name"
    echo "Creating $path"
    touch "$path"
done
