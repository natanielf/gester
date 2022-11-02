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

    n=0

    echo "Ingesting $(basename "$source")/ to $(basename "$target")/"
    # Copy all files from source to target location
    for file in "$source"*
    do
        # Get the creation date of the media
        date=$(exiftool -p '${CreateDate#;DateFmt("%Y-%m-%d")}' "$file" 2>/dev/null)

        # Use modification date as a fallback
        if [ -z "$date" ]
        then
            date=$(exiftool -p '${FileModifyDate#;DateFmt("%Y-%m-%d")}' "$file" 2>/dev/null)
        fi

        # If no modification date is available, use the date of last access
        if [ -z "$date" ]
        then
            date=$(exiftool -p '${FileAccessDate#;DateFmt("%Y-%m-%d")}' "$file" 2>/dev/null)
        fi

        target_subdir="$target$date"
        # Create subdirectory inside target location based on file's
        # EXIF creation date if it does not already exist
        if [ ! -d "$target_subdir" ]
        then
            mkdir "$target_subdir"
            echo "Created directory $date/"
        fi
        # Copy file to target subdirectory
        cp "$file" "$target_subdir"
        ((n++))
        echo "Copied $(basename "$file") to $(basename "$target_subdir")/"
    done
    echo "Ingest complete. $n files copied."
}

if [ -n "$source" ] && [ -n "$target" ]
then
    ingest
else
    configure
fi
