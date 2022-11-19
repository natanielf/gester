#!/bin/bash

usage() {
    echo "Usage: ./gester.sh [SOURCE] [TARGET]"
    echo "Ingest media files from the source directory to the target directory."
}

configure () {
    # Ask for source location if not already given
    echo "Enter source location as '/path/to/source' (where your media is right now)"
    read -r SOURCE
    while [ ! -d "$SOURCE" ]
    do
        echo "'$SOURCE' is not a valid directory."
        read -r SOURCE  
    done

    echo "Source location: $SOURCE"

    # Ask for target location if not already given
    echo "Enter target location as '/path/to/target' (where you want your media copied)"
    read -r TARGET
    while [ ! -d "$TARGET" ]
    do
        echo "'$TARGET' is not a valid directory."
        read -r TARGET
    done

    echo "Target location: $TARGET"

    echo "Choose a date format for subdirectories:"
    select DATE_FORMAT in "YYYY-MM-DD (default)" "YYYY/MM/DD" "YYYY/MM"
    do
        case "$DATE_FORMAT" in
            "YYYY/MM/DD")
                DATE_FORMAT="%Y/%m/%d"
                break
            ;;
            "YYYY/MM")
                DATE_FORMAT="%Y/%m"
                break
            ;;
            "YYYY-MM-DD (default)" | *)
                DATE_FORMAT="%Y-%m-%d"
                break
            ;;
        esac
    done

    ingest "$DATE_FORMAT"
}

ingest () {
    # Count the number of files ingested
    N=0

    # Set the default date format if none is specified
    DATE_FORMAT="$1"
    if [ -z "$DATE_FORMAT" ]
    then
        DATE_FORMAT="%Y-%m-%d"
    fi

    echo "Ingesting $(basename "$SOURCE")/ to $(basename "$TARGET")/"
    # Copy all files from source to target location
    for FILE in "$SOURCE"*
    do
        # Get the creation date of the media
        DATE=$(exiftool -S -CreateDate -d "$DATE_FORMAT" -S "$FILE" 2>/dev/null)

        # Use modification date as a fallback
        if [ -z "$DATE" ]
        then
            DATE=$(exiftool -S -FileModifyDate -d "$DATE_FORMAT" -S "$FILE" 2>/dev/null)
        fi

        # If no modification date is available, use the date of last access
        if [ -z "$DATE" ]
        then
            DATE=$(exiftool -S -FileAccessDate -d "$DATE_FORMAT" -S "$FILE" 2>/dev/null)
        fi

        TARGET_SUBDIR="$TARGET$DATE"
        # If the directory does not already exist, create a subdirectory
        # inside target location based on file's EXIF data
        if [ ! -d "$TARGET_SUBDIR" ]
        then
            mkdir -p "$TARGET_SUBDIR"
            echo "Created directory: '$DATE/'"
        fi
        # Copy file to target subdirectory
        cp "$FILE" "$TARGET_SUBDIR"
        # Check if the file has actually been copied
        FILE_BASENAME="$(basename "$FILE")"
        if [ -z "$(diff -q "$FILE" "$TARGET_SUBDIR/$FILE_BASENAME" 2>/dev/null)" ]
        then
            echo "Copied '$FILE_BASENAME' to '$DATE/'"
            N=$((N+1))
        else
            echo "Error: '$FILE_BASENAME' was not ingested."
        fi
    done
    echo "Ingest complete. $N files copied."
}

SOURCE=$1
TARGET=$2

if [ -n "$SOURCE" ] && [ -n "$TARGET" ]
then
    ingest
else
    configure
fi
