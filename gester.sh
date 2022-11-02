#!/bin/bash

usage() {
    echo "Usage: ./gester.sh [SOURCE] [TARGET]"
    echo "Ingest files from a source directory to a target directory."
}

configure () {
    # Ask for source location if not already given
    echo "Choose the source location (where your media is right now)"
    source=$(gum input --placeholder="path/to/media")
    while [ ! -d "$source" ]
    do
        echo "$source is not a valid directory."
        source=$(gum input --placeholder="path/to/media" --value="$source")
    done

    echo "Source: $source"

    # Ask for target location if not already given
    target=$(gum input --placeholder="path/to/target")
    while [ ! -d "$target" ]
    do
        echo "$source is not a valid directory."
        source=$(gum input --placeholder="path/to/target" --value="$target")
    done

    date_format="$(gum choose "YYYY-MM-DD" "YYYY/MM/DD" "YYYY/MM")"

    case $date_format in
        "YYYY-MM-DD")
            date_format="%Y-%m-%d"
        ;;
        "YYYY/MM/DD")
            date_format="%Y/%m/%d"
        ;;
        "YYYY/MM")
            date_format="%Y/%m"
        ;;
    esac

    echo "Target: $target"

    ingest $date_format
}

ingest () {
    # Count the number of files ingested
    n=0

    # Set the default date format if none is specified
    date_format=$1
    if [ -z "$date_format" ]
    then
        date_format="%Y-%m-%d"
    fi

    echo "Ingesting $(basename "$source")/ to $(basename "$target")/"
    # Copy all files from source to target location
    for file in "$source"*
    do
        # Get the creation date of the media
        date=$(exiftool -S -CreateDate -d "$date_format" -S "$file" 2>/dev/null)

        # Use modification date as a fallback
        if [ -z "$date" ]
        then
            date=$(exiftool -S -FileModifyDate -d "$date_format" -S "$file" 2>/dev/null)
        fi

        # If no modification date is available, use the date of last access
        if [ -z "$date" ]
        then
            date=$(exiftool -S -FileAccessDate -d "$date_format" -S "$file" 2>/dev/null)
        fi

        target_subdir="$target$date"
        # Create subdirectory inside target location based on file's
        # EXIF creation date if it does not already exist
        if [ ! -d "$target_subdir" ]
        then
            mkdir -p "$target_subdir"
            echo "Created directory $date/"
        fi
        # Copy file to target subdirectory
        cp "$file" "$target_subdir"
        ((n++))
        echo "Copied $(basename "$file") to $(basename "$target_subdir")/"
    done
    echo "Ingest complete. $n files copied."
}

source=$1
target=$2

if [ -n "$source" ] && [ -n "$target" ]
then
    ingest
else
    configure
fi
