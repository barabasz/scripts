#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sort media files into date-based folders by reading EXIF creation date.
Requires: ExifTool command-line tool and PyExifTool Python library.
Author: github.com/barabasz
"""

import argparse
from datetime import datetime
import os
import sys
import time
from typing import Dict, List, Union
from pathlib import Path

# Configuration variables
SCRIPT_NAME = "organize_media"
SCRIPT_VERSION = "0.25"
SCRIPT_DATE = "2025-10-11"
SCRIPT_AUTHOR = "github.com/barabasz"

EXTENSIONS = ['jpg', 'jpeg', 'dng', 'mov', 'mp4', 'orf', 'ori', 'raw']
FALLBACK_FOLDER = "UNKNOWN_DATE"  # Folder for media files without EXIF date
FILE_TEMPLATE = "YYYYMMDD-HHMMSS"  # Format for timestamp prefix
FOLDER_TEMPLATE = "YYYYMMDD"  # Template for folder names
INDENT = "    "  # Indentation for printed messages
INTERFIX = ""  # Text to insert between timestamp prefix and original filename
NORMALIZE_FILENAME = True  # Whether to normalize filenames (lowercase)
OFFSET = 0  # Time offset in seconds to apply to EXIF dates
OVERWRITE = False  # Whether to overwrite existing files during move operation
QUIET_MODE = False  # Whether to suppress non-error messages and prompts
SHOW_VERSION = False  # Whether to show version and exit
SOURCE_DIR = Path.cwd()  # Directory to organize (default: current working directory)
SOURCE_DIR_WRITABLE = False  # Whether the source directory is writable
TEST_MODE = False  # Test mode: show what would be done without making changes
TIME_DAY_STARTS = "04:00:00"  # Time when the new day starts for media grouping
USE_FALLBACK_FOLDER = False  # Whether to move files without date to fallback folder
USE_PREFIX = True  # Whether to add timestamp prefix to filenames
USE_SUBDIRS = False  # Whether to process files in subdirectories
VERBOSE_MODE = False  # Whether to print detailed information during processing
YES_TO_ALL = False  # Whether to assume 'yes' to all prompts

def parse_args() -> None:
    """Parse command line arguments and update configuration variables."""

    global OFFSET, FOLDER_TEMPLATE, FILE_TEMPLATE, INTERFIX, TIME_DAY_STARTS, USE_PREFIX
    global FALLBACK_FOLDER, OVERWRITE, USE_FALLBACK_FOLDER, VERBOSE_MODE, SHOW_VERSION
    global USE_PREFIX, EXTENSIONS, SOURCE_DIR, SCRIPT_NAME, TEST_MODE, USE_SUBDIRS
    global QUIET_MODE, INCLUDE_DOTFILES, YES_TO_ALL, NORMALIZE_FILENAME, SOURCE_DIR_WRITABLE

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
    parser.add_argument("--no-normalize", action="store_false", dest="normalize_filename",
                        help="Do not normalize filenames to lowercase")
    parser.add_argument("--no-subdirs", action="store_false", dest="include_subdirs",
                        help="Do not move files in subdirectories (rename in place)")
    # Positional arguments
    parser.add_argument("directory", type=str, default=SOURCE_DIR, nargs="?",
                    help="Directory to organize (default: current working directory)")
    # Parse arguments
    args = parser.parse_args()
    
    # Update configuration based on command line arguments
    EXTENSIONS = [ext.lower().lstrip('.') for ext in args.extensions]
    FALLBACK_FOLDER = args.fallback_folder
    FILE_TEMPLATE = args.file_template
    FOLDER_TEMPLATE = args.directory_template
    INTERFIX = args.interfix
    NORMALIZE_FILENAME = args.normalize_filename
    OFFSET = args.offset
    OVERWRITE = args.replace
    QUIET_MODE = args.quiet
    SHOW_VERSION = args.version
    SOURCE_DIR = Path(args.directory).resolve()
    SOURCE_DIR_WRITABLE = os.access(SOURCE_DIR, os.W_OK)
    TEST_MODE = args.test
    TIME_DAY_STARTS = args.new_day
    USE_FALLBACK_FOLDER = not args.skip_fallback
    USE_PREFIX = args.add_timestamp_prefix
    USE_SUBDIRS = args.include_subdirs
    VERBOSE_MODE = args.verbose
    YES_TO_ALL = args.yes

def printe(message: str, exit_code: int = 1) -> None:
    """Print and exit."""
    msg: str = message if exit_code == 0 else f"{_red}Error{_reset}: {message}"
    print(msg)
    sys.exit(exit_code)

def check_conditions() -> None:
    """Validate command line arguments and exit if invalid."""
    msg: str = ""
    code: int = 0

    if SHOW_VERSION:
        msg = f"{_green}{SCRIPT_NAME}{_reset} version {_cyan}{SCRIPT_VERSION}{_reset} ({SCRIPT_DATE}) by {_cyan}{SCRIPT_AUTHOR}{_reset}"
    if not SOURCE_DIR.is_dir():
        dir: str = f"{_cyan}{SOURCE_DIR}{_reset}"
        msg = f"The specified directory '{dir}' does not exist or is not a directory."
        code = 1
    elif not SOURCE_DIR_WRITABLE:
        dir: str = f"{_cyan}{SOURCE_DIR}{_reset}"
        msg = f"The specified directory '{dir}' is not writable."
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
    file_org: str = "FileName.Ext"
    arrow: str = f"{_yellow}→{_reset}"
    folder: str = f"{_cyan}{FOLDER_TEMPLATE}{_reset}"
    prefix: str = f"{_cyan}{FILE_TEMPLATE}{_reset}"
    separator: str = f"{_cyan}{INTERFIX}{_reset}"
    file_new: str = file_org.lower() if NORMALIZE_FILENAME else file_org
    if USE_PREFIX:
        separator = f"-{INTERFIX}-" if INTERFIX != "" else "-"
        file_new = f"{prefix}{separator}{file_new}"
    return f"{file_org} {arrow} {folder}/{file_new}"

def print_schema() -> None:
    """Print the current schema."""
    print(f"{_yellow}Schema:{_reset}")
    print(f"{INDENT}{get_schema()}")

def print_settings() -> None:
    """Print current settings."""
    print(f"{_yellow}RAW Settings:{_reset}")
    print(f"{INDENT}EXTENSIONS: {_cyan}{EXTENSIONS}{_reset}")
    print(f"{INDENT}FALLBACK_FOLDER: {_cyan}{FALLBACK_FOLDER}{_reset}")
    print(f"{INDENT}FILE_TEMPLATE: {_cyan}{FILE_TEMPLATE}{_reset}")
    print(f"{INDENT}FOLDER_TEMPLATE: {_cyan}{FOLDER_TEMPLATE}{_reset}")
    print(f"{INDENT}INTERFIX: {_cyan}{INTERFIX}{_reset}")
    print(f"{INDENT}NORMALIZE_FILENAME: {_cyan}{NORMALIZE_FILENAME}{_reset}")
    print(f"{INDENT}OFFSET: {_cyan}{OFFSET}{_reset}")
    print(f"{INDENT}OVERWRITE: {_cyan}{OVERWRITE}{_reset}")
    print(f"{INDENT}QUIET_MODE: {_cyan}{QUIET_MODE}{_reset}")
    print(f"{INDENT}SHOW_VERSION: {_cyan}{SHOW_VERSION}{_reset}")
    print(f"{INDENT}SOURCE_DIR: {_cyan}{SOURCE_DIR}{_reset}")
    print(f"{INDENT}SOURCE_DIR_WRITABLE: {_cyan}{SOURCE_DIR_WRITABLE}{_reset}")
    print(f"{INDENT}TEST_MODE: {_cyan}{TEST_MODE}{_reset}")
    print(f"{INDENT}TIME_DAY_STARTS: {_cyan}{TIME_DAY_STARTS}{_reset}")
    print(f"{INDENT}USE_FALLBACK_FOLDER: {_cyan}{USE_FALLBACK_FOLDER}{_reset}")
    print(f"{INDENT}USE_PREFIX: {_cyan}{USE_PREFIX}{_reset}")
    print(f"{INDENT}USE_SUBDIRS: {_cyan}{USE_SUBDIRS}{_reset}")
    print(f"{INDENT}VERBOSE_MODE: {_cyan}{VERBOSE_MODE}{_reset}")
    print(f"{INDENT}YES_TO_ALL: {_cyan}{YES_TO_ALL}{_reset}")

def print_header() -> None:
    """Print script header with version information."""
    global start_time
    start_time = time.time()
    print(f"{_green}Media Organizer Script{_reset} ({_green}{SCRIPT_NAME}{_reset}) v{SCRIPT_VERSION}{_reset}")
    if VERBOSE_MODE and not QUIET_MODE:
        print_settings()
    if QUIET_MODE and not VERBOSE_MODE:
        return
    print(f"{_yellow}Settings:{_reset}")
    if VERBOSE_MODE:
        print(f"{INDENT}Verbose mode: {_cyan}ON{_reset}")
    if TEST_MODE or VERBOSE_MODE:
        print(f"{INDENT}Test mode: {_cyan}{'ON' if TEST_MODE else 'OFF'}{_reset}")
    print(f"{INDENT}Include extensions: {_cyan}{', '.join(EXTENSIONS)}{_reset}")
    print(f"{INDENT}Subfolder template: {_cyan}{FOLDER_TEMPLATE}{_reset}")
    if VERBOSE_MODE:
        print(f"{INDENT}Add timestamp prefix: {_cyan}{USE_PREFIX}{_reset}")
    if USE_PREFIX:
        print(f"{INDENT}Filename format: {_cyan}{FILE_TEMPLATE}{_reset}")
    print(f"{INDENT}Day starts time set to: {_cyan}{TIME_DAY_STARTS}{_reset}")
    if USE_FALLBACK_FOLDER:
        print(f"{INDENT}Fallback folder name: {_cyan}{FALLBACK_FOLDER}{_reset}")
    if OVERWRITE:
        print(f"{INDENT}Overwrite existing files: {_cyan}{OVERWRITE}{_reset}")
    if OFFSET != 0:
        print(f"{INDENT}Time offset: {_cyan}{OFFSET} seconds{_reset}")
    if INTERFIX or VERBOSE_MODE:
        print(f"{INDENT}Interfix: {_cyan}{INTERFIX}{_reset}")
    if NORMALIZE_FILENAME or VERBOSE_MODE:
        print(f"{INDENT}Normalize filenames to lowercase: {_cyan}{'ON' if NORMALIZE_FILENAME else 'OFF'}{_reset}")


def get_elapsed_time() -> float:
    """Get elapsed time since script start in milliseconds."""
    elapsed_time: float = (time.time() - start_time) * 1000
    time_factor: str = "ms" if elapsed_time < 1000 else "s"
    elapsed_time = elapsed_time / 1000 if elapsed_time >= 1000 else elapsed_time  # Convert to seconds if >= 1000 ms
    return f"{elapsed_time:.2f}", time_factor

def print_footer(folder_info: Dict) -> None:
    """Print script footer."""
    time_elapsed, time_factor = get_elapsed_time()
    #print(f"Total media files: {media_count}")
    #print(f"Total processed files: {done_count}")
    #print(f"Total directories created: {dirs_count}")
    print(f"{_green}{SCRIPT_NAME}{_reset} completed in {_cyan}{time_elapsed}{_reset} {time_factor}.{_reset}")

def prompt_user(folder_info: Dict[str, int]) -> None:
    """Ask user for confirmation to continue."""
    if YES_TO_ALL or TEST_MODE:
        return
    prompt = f"{_yellow}Do you want to continue with {folder_info['media_count']} files? (Y/n): {_reset}"
    answer = input(prompt).strip().lower()
    if answer in ('n', 'no'):
        printe("Operation cancelled by user.", 0)

def get_media_objects(file_list: list[Path]) -> list[FileItem]:
    """Convert list of Paths to list of FileItem objects."""
    return [FileItem(file) for file in file_list if file.suffix.lstrip('.').lower() in EXTENSIONS]

def get_file_list(directory: Path) -> list[Path]:
    """Get a sorted list of file Paths in the specified directory."""
    files = [Path(file) for file in os.listdir(directory) if os.path.isfile(file)]
    return sorted(files, key=lambda x: x.name.lower())

def get_folder_info(file_list: list[Path]) -> Dict[str, int | float | str | set | Dict[str, int]]:
    """Get information about the folder."""
    info: Dict[str, int | float | str | set | Dict[str, int]] = {}
    info["path"] = SOURCE_DIR
    info["created"] = datetime.fromtimestamp(SOURCE_DIR.stat().st_ctime).strftime("%Y-%m-%d %H:%M:%S")
    info["modified"] = datetime.fromtimestamp(SOURCE_DIR.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
    info["file_count"] = len(file_list)
    info["media_count"] = sum(1 for file in file_list if file.suffix.lstrip('.').lower() in EXTENSIONS)
    media_types: Dict[str, int] = {}
    for f in file_list:
        ext = f.suffix.lstrip(".").lower()
        if ext in EXTENSIONS:
            media_types[ext] = media_types.get(ext, 0) + 1
    info["media_types"] = media_types
    return info

def print_folder_info(folder_info: Dict) -> None:
    """Print information about the folder and media files."""
    print(f"{_yellow}Folder:{_reset}")
    print(f"{INDENT}Path: {_cyan}{SOURCE_DIR}{_reset}")
    print(f"{INDENT}Created: {_cyan}{folder_info['created']}{_reset}")
    print(f"{INDENT}Modified: {_cyan}{folder_info['modified']}{_reset}")
    print(f"{INDENT}Total files: {_cyan}{folder_info['file_count']}{_reset}")
    print(f"{INDENT}Media files: {_cyan}{folder_info['media_count']}{_reset}", end="")
    print(f" ({', '.join(f'{_cyan}{count}{_reset} x {_cyan}{ext.upper()}{_reset}' for ext, count in folder_info['media_types'].items())})")

def process_files(media_list: List[FileItem], folder_info: Dict) -> None:
    """Process and organize media files."""
    processed_files: Dict[str, int] = {}
    skipped_files: Dict[str, int] = {}
    created_dirs: Dict[str, int] = {}

    for file in media_list:
        if file.size > 0 and file.readable and file.writable:
            print(f"Processing file: {_yellow}{file.name_old}{_reset}")
            print(f"{INDENT}path_old: {file.path_old}")
            print(f"{INDENT}subdir: {file.subdir}")
            print(f"{INDENT}stem: {file.stem}")
            print(f"{INDENT}ext: {file.ext}")
            print(f"{INDENT}name_new: {file.name_new}")
            print(f"{INDENT}path_new: {file.path_new}")
            print(f"{INDENT}size: {file.size} bytes")
            processed_files[file.ext] = processed_files.get(file.ext, 0) + 1
        else:
            skipped_files[file.ext] = skipped_files.get(file.ext, 0) + 1

    folder_info['processed_files'] = processed_files
    folder_info['skipped_files'] = skipped_files
    folder_info['created_dirs'] = created_dirs
    return None

class FileItem:
    """Class representing a file with its path and name."""
    # Attributes
    subdir: Path
    path_old: Path
    path: Path
    stem_old: str
    stem: str
    ext_old: str
    ext: str
    name_old: str
    name: str
    size: int
    readable: bool
    writable: bool
    prefix: str

    def get_subdir(self) -> Path:
        return Path("YYYYMMDD")
    
    def get_prefix(self) -> str:
        return "PREFIX"

    def get_new_name(self) -> str:
        name: str = ""
        if self.prefix:
            name += self.prefix + "-"
        if INTERFIX:
            name += "-" + INTERFIX + "-"
        return f"{name}{self.stem}.{self.ext}"

    def __init__(self, path: Path):
        """Initialize FileItem with path and extract attributes."""
        self.path_old = path.absolute()
        self.name_old = path.name
        self.stem_old = path.stem
        self.ext_old = path.suffix

        self.size = path.stat().st_size
        self.readable = os.access(path, os.R_OK)
        self.writable = os.access(path, os.W_OK)

        self.subdir = self.get_subdir()
        self.prefix = self.get_prefix()
        self.stem = path.stem.lower() if NORMALIZE_FILENAME else path.stem
        self.ext = self.ext_old.lstrip(".").lower() if NORMALIZE_FILENAME else self.ext_old.lstrip(".")
        self.name_new = self.get_new_name()
        self.path_new = Path(SOURCE_DIR / self.subdir / self.name_new).absolute()

def main() -> None:
    """Main function to organize media files."""
    init_colors()
    parse_args()
    check_conditions()
    print_header()
    file_list = get_file_list(Path(SOURCE_DIR))
    folder_info = get_folder_info(file_list)
    print_folder_info(folder_info)
    print_schema()
    prompt_user(folder_info)
    files = get_media_objects(file_list)
    process_files(files, folder_info)
    print_footer(folder_info)

# Run the main function
if __name__ == "__main__":
    main()