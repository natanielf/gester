#!/bin/bash
# Gester: A shell script for automating media ingest.

usage() {
    echo "Gester: A shell script for automating media ingest."
    echo "Usage: ./gester.sh SOURCE TARGET DATE_FORMAT"
    echo "date_format Usage: YYYY = year, MM = month, DD = day"
    echo "Example: ./gester.sh /path/to/source /path/to/target YYYY-MM-DD"
}

configure() {
    # Ask for source location if not already given
    echo "Enter source location as '/path/to/source' (where your media is right now)"
    read -r source
    while [ ! -d "$source" ]
    do
        echo "'$source' is not a valid directory."
        read -r source  
    done

    # Ask for target location if not already given
    echo "Enter target location as '/path/to/target' (where you want your media copied)"
    read -r target
    while [ ! -d "$target" ]
    do
        echo "'$target' is not a valid directory."
        read -r target
    done

    # Ask for the desired date format from a list of preset options
    echo "Choose a date format for subdirectories:"
    select date_format in "YYYY-MM-DD" "YYYYMMDD" "YYYY/MM/DD" "YYYY/MM"
    do
        ingest
    done
}

ingest() {
    # Check for invalid date formats
    if [[ "$date_format" != *"YYYY"* ]] && [[ "$date_format" != *"MM"* ]] && [[ "$date_format" != *"DD"* ]]
    then
        echo "Invalid date format specified: '$date_format'"
        exit 1
    fi

    # Convert human-readable date formats to the symbols used by exiftool
    date_format="${date_format/YYYY/%Y}"
    date_format="${date_format/MM/%m}"
    date_format="${date_format/DD/%d}"

    echo "Ingesting $(basename "$source")/ to $(basename "$target")/"
    # Count the number of files ingested
    n=0
    # Copy all files from source to target location
    for file in "$source"*
    do
        # Get the creation date of the media
        date=$(exiftool -S -CreateDate -d "$date_format" -S "$file")

        # Use modification date as a fallback
        if [ -z "$date" ]
        then
            date=$(exiftool -S -FileModifyDate -d "$date_format" -S "$file")
        fi

        # If no modification date is available, use the date of last access
        if [ -z "$date" ]
        then
            date=$(exiftool -S -FileAccessDate -d "$date_format" -S "$file")
        fi

        target_subdir="$target$date"

        # If the directory does not already exist, create a subdirectory
        # inside target location based on file's EXIF data
        if [ ! -d "$target_subdir" ]
        then
            mkdir -p "$target_subdir"
            echo "Created directory: '$date/'"
        fi

        # Copy file to target subdirectory
        cp -r --preserve=all "$file" "$target_subdir"

        # Check if the file has actually been copied
        file_basename=$(basename "$file")
        diff_check=$(diff -q "$file" "$target_subdir/$file_basename")
        if [ -z "$diff_check" ]
        then
            echo "Copied '$file_basename' to '$date/'"
            n=$((n+1))
        else
            echo "Error: '$file_basename' was not ingested."
            exit 1
        fi
    done
    echo "Ingest complete. $n files copied."
}

source=$1
target=$2
date_format=$3

if [ -d "$source" ] && [ -d "$target" ]
then
    ingest
elif [ -z "$source" ] && [ -z "$target" ]
then
    configure
else
    echo "Error: Invalid directory supplied."
    usage
    exit 1
fi
