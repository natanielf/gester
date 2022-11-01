#!/bin/bash

source=$1
target=$2

configure () {
    # Ask for source location if not already given
    if [ -z "$source" ]
    then
        echo "Choose the source location (where your media is right now)"
        source=$(dir -d "/run/media/$USER/" | gum choose)
    fi

    echo "Source: $source"

    # Ask for target location if not already given
    if [ -z "$target" ]
    then
        echo "Choose the target location (where you want your media copied to)"
        target=$(dir -d "$HOME/" | gum choose)
    fi

    echo "Target: $target"
}

ingest () {
    # Would be nice to use something like this
    # instead of a for loop, but because of the
    # subdir creation, it may not be any better
    # find "$source" -exec cp -r {} "$target" \;

    echo "Copying files from $source to $target"
    # Copy all files from source to target location
    for file in "$source"*
    do
        echo "$file"
        # Get the creation date of the media, use modification date
        # as a fallback
        date=$(exiftool -p '${CreateDate#;DateFmt("%Y-%m-%d")}' "$file")

        if [[ $date == "W*" ]]
        then
            date=$(exiftool -p '${FileModifyDate#;DateFmt("%Y-%m-%d")}' "$file")
            echo "Using modification date"
        fi

        target_subdir="$target$date"
        # Create subdirectory inside target location based on file's
        # EXIF creation date if it does not already exist
        if [ ! -d "$target_subdir" ]
        then
            mkdir "$target_subdir"
            echo "Created $target_subdir"
        fi
        # Copy file to target subdirectory
        cp "$file" "$target_subdir"
        echo "Copied $file to $target_subdir"
    done
}

if [ -n "$source" ] && [ -n "$target" ]
then
    ingest
else
    configure
fi
