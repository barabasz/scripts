#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sort media files into date-based folders by reading EXIF creation date.
Requires: ExifTool command-line tool and PyExifTool Python library.
Author: github.com/barabasz
"""

import argparse
import time
from pathlib import Path

# Configuration variables
SCRIPT_NAME = "organize_media"
SCRIPT_VERSION = "0.22"
EXTENSIONS = ['jpg', 'jpeg', 'dng', 'orf', 'ori', 'raw']
FALLBACK_FOLDER = "UNKNOWN_DATE"  # Folder for media files without EXIF date
TIME_DAY_STARTS = "04:00:00"  # Time when the new day starts for media grouping
FOLDER_TEMPLATE = "YYYYMMDD"  # Template for folder names
FILE_TEMPLATE = "YYYYMMDD-HHMMSS"  # Format for timestamp prefix

INCLUDE_DOTFILES = False  # Whether to include files starting with a dot
USE_FALLBACK_FOLDER = False  # Whether to move files without date to fallback folder
OVERWRITE = False  # Whether to overwrite existing files during move operation
ADD_TIMESTAMP_PREFIX = True  # Whether to add timestamp prefix to filenames

OFFSET = 0  # Time offset in seconds to apply to EXIF dates
INTERFIX = ""  # Text to insert between timestamp prefix and original filename
INDENT = "    "  # Indentation for printed messages
VERBOSE = False  # Whether to print detailed information during processing
SOURCE_DIR = Path.cwd()  # Directory to organize (default: current working directory)

def parse_args() -> None:
    """Parse command line arguments and update configuration variables."""

    global OFFSET, FOLDER_TEMPLATE, FILE_TEMPLATE, INTERFIX, TIME_DAY_STARTS
    global FALLBACK_FOLDER, OVERWRITE, USE_FALLBACK_FOLDER, VERBOSE
    global ADD_TIMESTAMP_PREFIX, EXTENSIONS, SOURCE_DIR, SCRIPT_NAME

    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Organize media files into date-based folders by reading EXIF creation date.\n" \
        f"Requires {_green}ExifTool{_reset} command-line tool and {_green}PyExifTool{_reset} Python library.\n" \
        f"Default schema: filename.ext → {_yellow}{FOLDER_TEMPLATE}/{FILE_TEMPLATE}-filename.ext{_reset}",
        epilog=f"Example: {_green}{SCRIPT_NAME}{_reset} -o 3600 --fallback-folder UNSORTED"
    )
    # Options with arguments
    parser.add_argument("-o", "--offset", type=int, default=OFFSET, metavar="SECONDS",
                        help="Time offset in seconds to apply to EXIF dates")
    parser.add_argument("-d", "--directory-template", type=str, default=FOLDER_TEMPLATE, metavar="TEMPLATE",
                        help=f"Template for directory names (default: '{_yellow}{FOLDER_TEMPLATE}{_reset}')")
    parser.add_argument("-e", "--extensions", type=str, nargs="+", default=EXTENSIONS, metavar="EXT",
                        help=f"List of file extensions to process (default: '{_yellow}{', '.join(EXTENSIONS)}{_reset}')")
    parser.add_argument("-f", "--file-template", type=str, default=FILE_TEMPLATE, metavar="TEMPLATE",
                        help=f"Template for file names (default: '{_yellow}{FILE_TEMPLATE}{_reset}')")
    parser.add_argument("-i", "--interfix", type=str, default=INTERFIX, metavar="TEXT",
                        help=f"Text to insert between timestamp prefix and original filename (default: '{_yellow}-{_reset}')")
    parser.add_argument("-n", "--new-day", type=str, default=TIME_DAY_STARTS, metavar="HH:MM:SS",
                        help=f"Time when the new day starts (default: '{_yellow}HH:MM:SS{_reset}')")
    parser.add_argument("-F", "--fallback-folder", type=str, default=FALLBACK_FOLDER, metavar="FOLDER",
                        help=f"Folder name for images without EXIF date (default: '{_yellow}UNKNOWN_DATE{_reset}')")
    parser.add_argument("-r", "--replace", action="store_true",
                        help="Replace (overwrite) existing files during move operation")
    parser.add_argument("-s", "--skip-fallback", action="store_true",
                        help="Do not move files without date to fallback folder")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Print detailed information during processing")
    # Flags
    parser.add_argument("--no-prefix", action="store_false", dest="add_timestamp_prefix",
                        help="Do not add timestamp prefix to filenames")
    # Positional arguments
    parser.add_argument("directory", type=str, default=SOURCE_DIR, nargs="?",
                    help="Directory to organize (default: current working directory)")
    # Parse arguments
    args = parser.parse_args()
    
    # Update configuration based on command line arguments
    OFFSET = args.offset
    FOLDER_TEMPLATE = args.directory_template
    EXTENSIONS = [ext.lower().lstrip('.') for ext in args.extensions]
    FILE_TEMPLATE = args.file_template
    ADD_TIMESTAMP_PREFIX = args.add_timestamp_prefix
    INTERFIX = args.interfix
    TIME_DAY_STARTS = args.new_day
    FALLBACK_FOLDER = args.fallback_folder
    OVERWRITE = args.replace
    USE_FALLBACK_FOLDER = not args.skip_fallback
    VERBOSE = args.verbose
    SOURCE_DIR = Path(args.directory).resolve()

def init_colors() -> None:
    """Initialize color codes for terminal output."""
    global _reset, _red, _green, _yellow, _cyan, _magenta
    _reset = "\033[0m"
    _red = "\033[31m"
    _green = "\033[32m"
    _yellow = "\033[33m"
    _cyan = "\033[36m"
    _magenta = "\033[35m"

def get_schema() -> str:
    """Generate and return the schema string based on current settings."""
    file_org: str = "filename.ext"
    arrow: str = f"{_yellow}→{_reset}"
    folder: str = f"{_cyan}{FOLDER_TEMPLATE}{_reset}"
    prefix: str = f"{_cyan}{FILE_TEMPLATE}{_reset}"
    separator: str = f"{_cyan}{INTERFIX}{_reset}"
    file_new: str = file_org
    if ADD_TIMESTAMP_PREFIX:
        separator = f"-{INTERFIX}-" if INTERFIX != "" else "-"
        file_new = f"{prefix}{separator}{file_org}"
    return f"{file_org} {arrow} {folder}/{file_new}"

def print_header() -> None:
    """Print script header with version information."""
    global start_time
    start_time = time.time()
    print(f"{_green}Media Organizer Script v{SCRIPT_VERSION}{_reset}")
    print(f"{_yellow}Settings:{_reset}")
    if VERBOSE:
        print(f"{INDENT}Verbose mode: {_cyan}ON{_reset}")
    print(f"{INDENT}Working directory: {_cyan}{SOURCE_DIR}{_reset}")
    print(f"{INDENT}Include extensions: {_cyan}{', '.join(EXTENSIONS)}{_reset}")
    print(f"{INDENT}Subfolder template: {_cyan}{FOLDER_TEMPLATE}{_reset}")
    if VERBOSE:
        print(f"{INDENT}Add timestamp prefix: {_cyan}{ADD_TIMESTAMP_PREFIX}{_reset}")
    if ADD_TIMESTAMP_PREFIX:
        print(f"{INDENT}Filename format: {_cyan}{FILE_TEMPLATE}{_reset}")
    print(f"{INDENT}Day starts time set to: {_cyan}{TIME_DAY_STARTS}{_reset}")
    if USE_FALLBACK_FOLDER:
        print(f"{INDENT}Fallback folder name: {_cyan}{FALLBACK_FOLDER}{_reset}")
    if INCLUDE_DOTFILES:
        print(f"{INDENT}Include dotfiles: {_cyan}{INCLUDE_DOTFILES}{_reset}")
    if OVERWRITE:
        print(f"{INDENT}Overwrite existing files: {_cyan}{OVERWRITE}{_reset}")

    if OFFSET != 0:
        print(f"{INDENT}Time offset: {_cyan}{OFFSET} seconds{_reset}")
    if INTERFIX or VERBOSE:
        print(f"{INDENT}Interfix: {_cyan}{INTERFIX}{_reset}")
    # Print schema
    print(f"{_yellow}Schema:{_reset}")
    print(f"{INDENT}{get_schema()}")

def get_elapsed_time() -> float:
    """Get elapsed time since script start in milliseconds."""
    elapsed_time: float = (time.time() - start_time) * 1000
    time_factor: str = "milliseconds" if elapsed_time < 1000 else "seconds"
    elapsed_time = elapsed_time / 1000 if elapsed_time >= 1000 else elapsed_time  # Convert to seconds if >= 1000 ms
    return f"{elapsed_time:.2f}", time_factor

def print_footer() -> None:
    """Print script footer."""
    time_elapsed, time_factor = get_elapsed_time()
    print(f"{_green}Media organization completed in {time_elapsed} {time_factor}.{_reset}")

def main() -> None:
    """Main function to organize media files."""
    init_colors()
    parse_args()
    print_header()
    # Placeholder for the main logic to organize media files
    print_footer()

# Run the main function
if __name__ == "__main__":
    main()