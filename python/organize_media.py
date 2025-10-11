#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sort media files into date-based folders by reading EXIF creation date.
Requires: ExifTool command-line tool and PyExifTool Python library.
Author: github.com/barabasz
"""

import argparse
import sys
import time
from typing import Dict, List, Union
from pathlib import Path

# Configuration variables
SCRIPT_NAME = "organize_media"
SCRIPT_VERSION = "0.22"
SCRIPT_DATE = "2024-06-10"

ADD_TIMESTAMP_PREFIX = True  # Whether to add timestamp prefix to filenames
EXTENSIONS = ['jpg', 'jpeg', 'dng', 'mov', 'mp4', 'orf', 'ori', 'raw']
FALLBACK_FOLDER = "UNKNOWN_DATE"  # Folder for media files without EXIF date
FILE_TEMPLATE = "YYYYMMDD-HHMMSS"  # Format for timestamp prefix
FOLDER_TEMPLATE = "YYYYMMDD"  # Template for folder names
INCLUDE_DOTFILES = False  # Whether to include files starting with a dot
INDENT = "    "  # Indentation for printed messages
INTERFIX = ""  # Text to insert between timestamp prefix and original filename
OFFSET = 0  # Time offset in seconds to apply to EXIF dates
OVERWRITE = False  # Whether to overwrite existing files during move operation
QUIET_MODE = False  # Whether to suppress non-error messages and prompts
YES_TO_ALL = False  # Whether to assume 'yes' to all prompts
SHOW_VERSION = False  # Whether to show version and exit
SOURCE_DIR = Path.cwd()  # Directory to organize (default: current working directory)
TEST_MODE = False  # Test mode: show what would be done without making changes
TIME_DAY_STARTS = "04:00:00"  # Time when the new day starts for media grouping
USE_FALLBACK_FOLDER = False  # Whether to move files without date to fallback folder
VERBOSE_MODE = False  # Whether to print detailed information during processing

def parse_args() -> None:
    """Parse command line arguments and update configuration variables."""

    global OFFSET, FOLDER_TEMPLATE, FILE_TEMPLATE, INTERFIX, TIME_DAY_STARTS
    global FALLBACK_FOLDER, OVERWRITE, USE_FALLBACK_FOLDER, VERBOSE_MODE, SHOW_VERSION
    global ADD_TIMESTAMP_PREFIX, EXTENSIONS, SOURCE_DIR, SCRIPT_NAME, TEST_MODE
    global QUIET_MODE, INCLUDE_DOTFILES, YES_TO_ALL

    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Organize media files into date-based folders by reading EXIF creation date.\n" \
        f"Requires {_green}ExifTool{_reset} command-line tool and {_green}PyExifTool{_reset} Python library.\n" \
        f"Default schema: {get_schema()}",
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
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Quiet mode (suppress non-error messages)")
    parser.add_argument("-r", "--replace", action="store_true",
                        help="Replace (overwrite) existing files during move operation")
    parser.add_argument("-s", "--skip-fallback", action="store_true",
                        help="Do not move files without date to fallback folder")
    parser.add_argument("-t", "--test", action="store_true",
                        help="Test mode: show what would be done without making changes")
    parser.add_argument("-v", "--version", action="store_true",
                        help="Print version and exit")
    parser.add_argument("-V", "--verbose", action="store_true",
                        help="Print detailed information during processing")
    parser.add_argument("-y", "--yes", action="store_true",
                        help="Assume 'yes' to all prompts")
    

    # Flags
    parser.add_argument("--no-prefix", action="store_false", dest="add_timestamp_prefix",
                        help="Do not add timestamp prefix to filenames")
    # Positional arguments
    parser.add_argument("directory", type=str, default=SOURCE_DIR, nargs="?",
                    help="Directory to organize (default: current working directory)")
    # Parse arguments
    args = parser.parse_args()
    
    # Update configuration based on command line arguments
    ADD_TIMESTAMP_PREFIX = args.add_timestamp_prefix
    EXTENSIONS = [ext.lower().lstrip('.') for ext in args.extensions]
    FALLBACK_FOLDER = args.fallback_folder
    FILE_TEMPLATE = args.file_template
    FOLDER_TEMPLATE = args.directory_template
    INTERFIX = args.interfix
    OFFSET = args.offset
    OVERWRITE = args.replace
    QUIET_MODE = args.quiet
    SHOW_VERSION = args.version
    SOURCE_DIR = Path(args.directory).resolve()
    TEST_MODE = args.test
    TIME_DAY_STARTS = args.new_day
    USE_FALLBACK_FOLDER = not args.skip_fallback
    VERBOSE_MODE = args.verbose
    YES_TO_ALL = args.yes

def printe(message: str, exit_code: int = 1) -> None:
    """Print and exit."""
    msg: str = message if exit_code == 0 else f"{_red}Error{_reset}: {message}"
    print(msg)
    sys.exit(exit_code)

def check_args() -> None:
    """Validate command line arguments and exit if invalid."""
    msg: str = ""
    code: int = 0

    if SHOW_VERSION:
        msg = f"{_green}{SCRIPT_NAME}{_reset} version {_cyan}{SCRIPT_VERSION}{_reset} ({SCRIPT_DATE})"
    if not SOURCE_DIR.is_dir():
        dir: str = f"{_cyan}{SOURCE_DIR}{_reset}"
        msg = f"The specified directory '{dir}' does not exist or is not a directory."
        code = 1
    if OFFSET < -86400 or OFFSET > 86400:
        msg = f"Offset must be between -86400 and 86400 seconds."
        code = 1
    if not EXTENSIONS:
        msg = f"At least one file extension must be specified."
        code = 1

    if msg:
        printe(msg, code)
    return None

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
    print(f"{_green}Media Organizer Script{_reset} ({_green}{SCRIPT_NAME}{_reset}) v{SCRIPT_VERSION}{_reset}")
    if QUIET_MODE and not VERBOSE_MODE:
        return
    print(f"{_yellow}Settings:{_reset}")
    if VERBOSE_MODE:
        print(f"{INDENT}Verbose mode: {_cyan}ON{_reset}")
    if TEST_MODE or VERBOSE_MODE:
        print(f"{INDENT}Test mode: {_cyan}{'ON' if TEST_MODE else 'OFF'}{_reset}")
    print(f"{INDENT}Working directory: {_cyan}{SOURCE_DIR}{_reset}")
    print(f"{INDENT}Include extensions: {_cyan}{', '.join(EXTENSIONS)}{_reset}")
    print(f"{INDENT}Subfolder template: {_cyan}{FOLDER_TEMPLATE}{_reset}")
    if VERBOSE_MODE:
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
    if INTERFIX or VERBOSE_MODE:
        print(f"{INDENT}Interfix: {_cyan}{INTERFIX}{_reset}")
    # Print schema
    print(f"{_yellow}Schema:{_reset}")
    print(f"{INDENT}{get_schema()}")

def get_elapsed_time() -> float:
    """Get elapsed time since script start in milliseconds."""
    elapsed_time: float = (time.time() - start_time) * 1000
    time_factor: str = "ms" if elapsed_time < 1000 else "s"
    elapsed_time = elapsed_time / 1000 if elapsed_time >= 1000 else elapsed_time  # Convert to seconds if >= 1000 ms
    return f"{elapsed_time:.2f}", time_factor

def print_footer(media_count: int, done_count: int, dirs_count: int) -> None:
    """Print script footer."""
    time_elapsed, time_factor = get_elapsed_time()
    print(f"Total media files: {media_count}")
    print(f"Total processed files: {done_count}")
    print(f"Total directories created: {dirs_count}")
    print(f"{_green}{SCRIPT_NAME}{_reset} completed in {_cyan}{time_elapsed}{_reset} {time_factor}.{_reset}")


def prompt_user() -> None:
    """Ask user for confirmation to continue."""
    if YES_TO_ALL or TEST_MODE:
        return
    answer = input(f"{_yellow}Do you want to continue? (Y/n): {_reset}").strip().lower()
    if answer in ('n', 'no'):
        printe("Operation cancelled by user.", 0)

def get_file_list(directory: Path) -> List[Path]:
    """Get a list of files in the specified directory."""
    return []

def get_media_list(file_list: List[Path]) -> List[Path]:
    """Filter and return a list of media files based on extensions."""
    return [f for f in file_list if f.suffix in EXTENSIONS]

def get_media_types(file_list: List[Path]) -> Dict[str, int]:
    """Get a dictionary of media file types and their counts."""
    pass

def print_folder_info(file_count: int, media_count: int, media_types: Dict[str, int]) -> None:
    """Print information about the folder and media files."""
    pass

def process_files(media_list: List[Path]) -> Union[int, int]:
    """Process and organize media files."""
    return 0, 0

def main() -> None:
    """Main function to organize media files."""
    init_colors()
    parse_args()
    check_args()
    print_header()

    # Initialize counters and lists
    file_list: List[Path] = []
    media_list: List[Path] = []
    media_types: Dict[str, int] = {}
    file_count: int = 0
    media_count: int = 0
    done_count: int = 0
    dirs_count: int = 0
    file_list = get_file_list(SOURCE_DIR)
    file_count = len(file_list)
    media_list = get_media_list(file_list)
    media_count = len(media_list)
    media_types = get_media_types(file_list)
    print_folder_info(file_count, media_count, media_types)
    prompt_user()

    # Process files
    done_count, dirs_count = process_files(media_list)

    print_footer(media_count, done_count, dirs_count)

# Run the main function
if __name__ == "__main__":
    main()