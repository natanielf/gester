# Gester

A shell script for automating media ingest.

# Usage

`./gester.sh SOURCE TARGET DATE_FORMAT`

Where:

- `SOURCE` is the directory of the source media (such the `DCIM` directory of a camera's SD card).
- `TARGET` is the directory in which you want to ingest media (where gester will copy media files to).
- `DATE_FORMAT` is the format of the subdirectories that will be created inside of `TARGET`. `YYYY` is for the year, `MM` is for the month, and `DD` is for the day.

Examples:

- `./gester.sh /path/to/source /path/to/target YYYY-MM-DD`
- `./gester.sh /path/to/source /path/to/target YYYY/MM/`
- `./gester.sh /path/to/source /path/to/target YYYY`

# Features

- Supports any media file that contains [EXIF metadata](https://wikipedia.org/wiki/Exif) that can be read by [ExifTool](https://exiftool.org/)
- Preserves `FileModifyDate` EXIF tag
- Configurable destination subdirectory formatting
- Checks for file parity after copying each file to ensure the copy was successful

# Required Software

- [ExifTool](https://exiftool.org/): Application for reading, writing and editing meta information.
