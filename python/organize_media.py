#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sort media files into date-based folders by reading EXIF creation date.
Requires: ExifTool command-line tool and PyExifTool Python library.
Author: github.com/barabasz
"""

import argparse
import datetime
import os
import subprocess
import sys
import time
from typing import Dict, List
from pathlib import Path

# Check if PyExifTool is installed
try:
    import exiftool
except ImportError:
    print("\033[0;31mPyExifTool extension is not installed.\033[0m")
    print("Please install it using: \033[0;36mpip install PyExifTool\033[0m")
    sys.exit(1)

# Check if ExifTool command-line tool is available
try:
    subprocess.run(['exiftool', '-ver'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
except (subprocess.SubprocessError, FileNotFoundError):
    print("\033[0;31mExifTool command-line tool is not installed or not in PATH.\033[0m")
    print("Please download and install it from: \033[0;36mhttps://exiftool.org/\033[0m")
    sys.exit(1)

# Configuration variables
SCRIPT_NAME = "organize_media"
SCRIPT_VERSION = "0.3"
SCRIPT_DATE = "2025-10-12"
SCRIPT_AUTHOR = "github.com/barabasz"

EXTENSIONS = ['jpg', 'jpeg', 'dng', 'mov', 'mp4', 'orf', 'ori', 'raw']
CHANGE_EXTENSIONS = {'jpeg': 'jpg', 'tiff': 'tif'}  # Map of extensions to change
EXIF_DATE_TAGS = ['EXIF:DateTimeOriginal', 'EXIF:CreateDate', 'XMP:CreateDate']
FALLBACK_FOLDER = "UNKNOWN_DATE"  # Folder for media files without EXIF date
FILE_TEMPLATE = "YYYYMMDD-HHMMSS"  # Format for timestamp prefix
FOLDER_TEMPLATE = "YYYYMMDD"  # Template for folder names
INDENT = "    "  # Indentation for printed messages
INTERFIX = ""  # Text to insert between timestamp prefix and original filename
NORMALIZE_EXT = True  # Whether to normalize extensions to 3-letter lowercase
OFFSET = 0  # Time offset in seconds to apply to EXIF dates
OVERWRITE = False  # Whether to overwrite existing files during move operation
QUIET_MODE = False  # Whether to suppress non-error messages and prompts
SHOW_VERSION = False  # Whether to show version and exit
SHOW_FILES_DETAILS = False  # Whether to show detailed file information
SHOW_FILES_ERRORS = False  # Whether to show files with errors
SHOW_RAW_SETTINGS = False  # Whether to show raw settings
SOURCE_DIR = Path.cwd()  # Directory to organize (default: current working directory)
SOURCE_DIR_WRITABLE = False  # Whether the source directory is writable
TEST_MODE = False  # Test mode: show what would be done without making changes
TIME_DAY_STARTS = "04:00:00"  # Time when the new day starts for media grouping
USE_FALLBACK_FOLDER = False  # Whether to move files without date to fallback folder
USE_PREFIX = True  # Whether to add timestamp prefix to filenames
USE_SUBDIRS = True  # Whether to process files in subdirectories
VERBOSE_MODE = False  # Whether to print detailed information during processing
YES_TO_ALL = False  # Whether to assume 'yes' to all prompts

def parse_args() -> None:
    """Parse command line arguments and update configuration variables."""

    global OFFSET, FOLDER_TEMPLATE, FILE_TEMPLATE, INTERFIX, TIME_DAY_STARTS
    global SHOW_FILES_DETAILS, USE_PREFIX, FALLBACK_FOLDER, OVERWRITE
    global USE_FALLBACK_FOLDER, VERBOSE_MODE, USE_PREFIX, EXTENSIONS
    global SOURCE_DIR, SCRIPT_NAME, TEST_MODE, USE_SUBDIRS, QUIET_MODE
    global INCLUDE_DOTFILES, YES_TO_ALL, NORMALIZE_EXT, SOURCE_DIR_WRITABLE
    global SHOW_RAW_SETTINGS, SHOW_VERSION, SHOW_FILES_ERRORS

    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Organize media files into date-based folders by reading EXIF creation date.\n" \
        f"Requires {_green}ExifTool{_reset} command-line tool and {_green}PyExifTool{_reset} Python library.\n" \
        f"Default schema: {get_schema()}",
        epilog=f"Example: {_green}{SCRIPT_NAME}{_reset} -o 3600 --fallback-folder UNSORTED"
    )
    # Options with arguments

    parser.add_argument("-d", "--directory-template", type=str, default=FOLDER_TEMPLATE, metavar="TEMPLATE",
                        help=f"Template for directory names (default: '{_yellow}{FOLDER_TEMPLATE}{_reset}')")
    parser.add_argument("-D", "--files-details", action="store_true", dest="show_files_details",
                        help="Show detailed information about each file")
    parser.add_argument("-e", "--extensions", type=str, nargs="+", default=EXTENSIONS, metavar="EXT",
                        help=f"List of file extensions to process (default: '{_yellow}{', '.join(EXTENSIONS)}{_reset}')")
    parser.add_argument("-E", "--show-errors", action="store_true", dest="show_files_errors",
                        help="Show files with errors")
    parser.add_argument("-f", "--file-template", type=str, default=FILE_TEMPLATE, metavar="TEMPLATE",
                        help=f"Template for file names (default: '{_yellow}{FILE_TEMPLATE}{_reset}')")
    parser.add_argument("-i", "--interfix", type=str, default=INTERFIX, metavar="TEXT",
                        help=f"Text to insert between timestamp prefix and original filename (default: '{_yellow}-{_reset}')")
    parser.add_argument("-n", "--new-day", type=str, default=TIME_DAY_STARTS, metavar="HH:MM:SS",
                        help=f"Time when the new day starts (default: '{_yellow}HH:MM:SS{_reset}')")
    parser.add_argument("-N", "--no-normalize", action="store_false", dest="normalize_ext",
                        help="Do not normalize extensions to 3-letter lowercase")
    parser.add_argument("-F", "--fallback-folder", type=str, default=FALLBACK_FOLDER, metavar="FOLDER",
                        help=f"Folder name for images without EXIF date (default: '{_yellow}UNKNOWN_DATE{_reset}')")
    parser.add_argument("-o", "--offset", type=int, default=OFFSET, metavar="SECONDS",
                        help="Time offset in seconds to apply to EXIF dates")
    parser.add_argument("-O", "--overwrite", action="store_true",
                        help="Overwrite existing files during move/rename operation")
    parser.add_argument("-p", "--no-prefix", action="store_false", dest="add_timestamp_prefix",
                        help="Do not add timestamp prefix to filenames")
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Quiet mode (suppress non-error messages)")
    parser.add_argument("-s", "--skip-fallback", action="store_true",
                        help="Do not move files without date to fallback folder")
    parser.add_argument("-S", "--settings", action="store_true", dest="show_raw_settings",
                        help="Show raw settings (variable values)")
    parser.add_argument("-r","--rename", action="store_false", dest="use_subdirs",
                        help="Rename in place (do not move files in subdirectories)")
    parser.add_argument("-t", "--test", action="store_true",
                        help="Test mode: show what would be done without making changes")
    parser.add_argument("-v", "--version", action="store_true",
                        help="Print version and exit")
    parser.add_argument("-V", "--verbose", action="store_true",
                        help="Print detailed information during processing")
    parser.add_argument("-y", "--yes", action="store_true",
                        help="Assume 'yes' to all prompts")
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
    NORMALIZE_EXT = args.normalize_ext
    OFFSET = args.offset
    OVERWRITE = args.overwrite
    QUIET_MODE = args.quiet
    SHOW_VERSION = args.version
    SHOW_FILES_DETAILS = args.show_files_details
    SHOW_FILES_ERRORS = args.show_files_errors
    SHOW_RAW_SETTINGS = args.show_raw_settings
    SOURCE_DIR = Path(args.directory).resolve()
    SOURCE_DIR_WRITABLE = os.access(SOURCE_DIR, os.W_OK)
    TEST_MODE = args.test
    TIME_DAY_STARTS = args.new_day
    USE_FALLBACK_FOLDER = not args.skip_fallback
    USE_PREFIX = args.add_timestamp_prefix
    USE_SUBDIRS = args.use_subdirs
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
    if not EXTENSIONS or all(ext.strip() == "" for ext in EXTENSIONS):
        msg = f"At least one file extension must be specified."
        code = 1
    if QUIET_MODE and VERBOSE_MODE:
        msg = "Cannot use both quiet mode and verbose mode."
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
    folder = f"{folder}/" if USE_SUBDIRS else ""
    prefix: str = f"{_cyan}{FILE_TEMPLATE}{_reset}"
    separator: str = f"{_cyan}{INTERFIX}{_reset}"
    file_new: str = file_org.lower() if NORMALIZE_EXT else file_org
    if USE_PREFIX:
        separator = f"-{INTERFIX}-" if INTERFIX != "" else "-"
        file_new = f"{prefix}{separator}{file_new}"
    return f"{file_org} {arrow} {folder}{file_new}"

def print_schema() -> None:
    """Print the current schema."""
    print(f"{_yellow}Schema:{_reset}")
    print(f"{INDENT}{get_schema()}")


def print_settings() -> None:
    """Print current settings."""
    print(f"{_yellow}RAW Settings:{_reset}")
    print(f"{INDENT}CHANGE_EXTENSIONS: {_cyan}{CHANGE_EXTENSIONS}{_reset}")
    print(f"{INDENT}EXIF_DATE_TAGS: {_cyan}{EXIF_DATE_TAGS}{_reset}")
    print(f"{INDENT}EXTENSIONS: {_cyan}{EXTENSIONS}{_reset}")
    print(f"{INDENT}FALLBACK_FOLDER: {_cyan}{FALLBACK_FOLDER}{_reset}")
    print(f"{INDENT}FILE_TEMPLATE: {_cyan}{FILE_TEMPLATE}{_reset}")
    print(f"{INDENT}FOLDER_TEMPLATE: {_cyan}{FOLDER_TEMPLATE}{_reset}")
    print(f"{INDENT}INTERFIX: {_cyan}{INTERFIX}{_reset}")
    print(f"{INDENT}NORMALIZE_EXT: {_cyan}{NORMALIZE_EXT}{_reset}")
    print(f"{INDENT}OFFSET: {_cyan}{OFFSET}{_reset}")
    print(f"{INDENT}OVERWRITE: {_cyan}{OVERWRITE}{_reset}")
    print(f"{INDENT}QUIET_MODE: {_cyan}{QUIET_MODE}{_reset}")
    print(f"{INDENT}SHOW_VERSION: {_cyan}{SHOW_VERSION}{_reset}")
    print(f"{INDENT}SHOW_FILES_DETAILS: {_cyan}{SHOW_FILES_DETAILS}{_reset}")
    print(f"{INDENT}SHOW_RAW_SETTINGS: {_cyan}{SHOW_RAW_SETTINGS}{_reset}")
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
    on = f"{_green}ON{_reset}"
    off = f"{_red}OFF{_reset}"
    print(f"{_green}Media Organizer Script{_reset} ({_green}{SCRIPT_NAME}{_reset}) v{SCRIPT_VERSION}{_reset}")
    if SHOW_RAW_SETTINGS and not QUIET_MODE:
        print_settings()
    print_schema()
    if QUIET_MODE:
        return
    print(f"{_yellow}Settings:{_reset}")
    if VERBOSE_MODE:
        print(f"{INDENT}Verbose mode: {on if VERBOSE_MODE else off}")
    if TEST_MODE or VERBOSE_MODE:
        print(f"{INDENT}Test mode: {on if TEST_MODE else off}")
    if EXTENSIONS:
        print(f"{INDENT}Include extensions: {_cyan}{', '.join(EXTENSIONS)}{_reset}")
    if VERBOSE_MODE or not USE_SUBDIRS:
        print(f"{INDENT}Process to subdirectories: {on if USE_SUBDIRS else off}")
    if USE_SUBDIRS:
        print(f"{INDENT}Subfolder template: {_cyan}{FOLDER_TEMPLATE}{_reset}")
    if VERBOSE_MODE or TIME_DAY_STARTS != "00:00:00":
        print(f"{INDENT}Day starts time set to: {_cyan}{TIME_DAY_STARTS}{_reset}")
    if VERBOSE_MODE or OVERWRITE:
        print(f"{INDENT}Overwrite existing files: {on if OVERWRITE else off}")
    if VERBOSE_MODE or not NORMALIZE_EXT:
        print(f"{INDENT}Normalize extensions: {on if NORMALIZE_EXT else off}")
    if VERBOSE_MODE or not USE_PREFIX:
        print(f"{INDENT}Add prefix to filenames: {on if USE_PREFIX else off}")
    if VERBOSE_MODE or USE_PREFIX:
        print(f"{INDENT}Prefix format: {_cyan}{FILE_TEMPLATE}{_reset}")
    if VERBOSE_MODE or not USE_FALLBACK_FOLDER:
        print(f"{INDENT}Use fallback folder: {on if USE_FALLBACK_FOLDER else off}")
    if USE_FALLBACK_FOLDER:
        print(f"{INDENT}Fallback folder name: {_cyan}{FALLBACK_FOLDER}{_reset}")
    if VERBOSE_MODE or OFFSET != 0:
        print(f"{INDENT}Time offset: {_cyan}{OFFSET} seconds{_reset}")
    if INTERFIX or VERBOSE_MODE:
        print(f"{INDENT}Interfix: {_cyan}{INTERFIX}{_reset}")


def get_elapsed_time() -> float:
    """Get elapsed time since script start in milliseconds."""
    elapsed_time: float = (time.time() - start_time) * 1000
    time_factor: str = "ms" if elapsed_time < 1000 else "s"
    elapsed_time = elapsed_time / 1000 if elapsed_time >= 1000 else elapsed_time  # Convert to seconds if >= 1000 ms
    return f"{elapsed_time:.2f}", time_factor


def print_footer(folder_info: Dict) -> None:
    """Print script footer."""
    time_elapsed, time_factor = get_elapsed_time()
    print(f"{_yellow}Summary:{_reset}")
    if TEST_MODE:
        print(f"{INDENT}Test mode (no changes made).")
    else:
        print(f"{INDENT}Processed files: {len(folder_info['processed_files'])}")
        print(f"{INDENT}Skipped files: {len(folder_info['skipped_files'])}")
        print(f"{INDENT}Directories created: {len(folder_info['created_dirs'])}")
    print(f"{INDENT}Completed in: {_cyan}{time_elapsed}{_reset} {time_factor}.{_reset}")


def prompt_user(folder_info: Dict[str, int]) -> bool:
    """Ask user for confirmation to continue."""
    if YES_TO_ALL or TEST_MODE:
        return True
    prompt = f"{_yellow}Do you want to continue with {folder_info['valid_files']} files? (yes/No): {_reset}"
    answer = input(prompt).strip().lower()
    if answer not in ('y', 'yes'):
        print("Operation cancelled by user.")
        return False
    return True


def get_media_objects(file_list: list[Path], folder_info: Dict) -> list[FileItem]:
    """Convert list of Paths to list of FileItem objects."""
    media_count = folder_info.get('media_count', 0)
    media_objects = []
    item: int = 1
    print(f"{_yellow}Analyzing files:{_reset}")
    for file in file_list:
        if file.suffix.lstrip('.').lower() in EXTENSIONS:
            media_item = FileItem(file)
            percentage = (item / media_count) * 100
            if SHOW_FILES_DETAILS and not QUIET_MODE:
                print_file_info(media_item)
            else:
                msg = f"\r\033[K\r{INDENT}File {item} of {media_count}: {_cyan}{file}{_reset} ({percentage:.0f}%)"
                print(msg, end="", flush=True)
            media_objects.append(media_item)
            item += 1
    if not SHOW_FILES_DETAILS:
        print(f"\r\033[K\r{INDENT}Completed.")
    return media_objects


def get_file_list(directory: Path) -> list[Path]:
    """Get a sorted list of file Paths in the specified directory."""
    files = [Path(file) for file in os.listdir(directory) if os.path.isfile(file)]
    return sorted(files, key=lambda x: x.name.lower())


def get_folder_info(file_list: list[Path]) -> Dict[str, int | float | str | set | Dict[str, int]]:
    """Get information about the folder."""
    info: Dict[str, int | float | str | set | Dict[str, int]] = {}
    info["path"] = SOURCE_DIR
    info["created"] = datetime.datetime.fromtimestamp(SOURCE_DIR.stat().st_ctime).strftime("%Y-%m-%d %H:%M:%S")
    info["modified"] = datetime.datetime.fromtimestamp(SOURCE_DIR.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
    info["file_count"] = len(file_list)
    info["media_count"] = sum(1 for file in file_list if file.suffix.lstrip('.').lower() in EXTENSIONS)
    media_types: Dict[str, int] = {}
    for f in file_list:
        ext = f.suffix.lstrip(".").lower()
        if ext in EXTENSIONS:
            media_types[ext] = media_types.get(ext, 0) + 1
    info["media_types"] = media_types
    info['processed_files'] = []
    info['skipped_files'] = []
    info['created_dirs'] = []
    return info


def print_folder_info(folder_info: Dict) -> None:
    """Print information about the folder and media files."""
    print(f"{_yellow}Folder info:{_reset}")
    print(f"{INDENT}Path: {_cyan}{SOURCE_DIR}{_reset}")
    print(f"{INDENT}Total files: {_cyan}{folder_info['file_count']}{_reset}")
    if VERBOSE_MODE:
        print(f"{INDENT}Matching files: {_cyan}{folder_info['media_count']}{_reset}", end="")
        print(f" ({', '.join(f'{_cyan}{count}{_reset} x {_cyan}{ext.upper()}{_reset}' for ext, count in folder_info['media_types'].items())})")
        print(f"{INDENT}Created: {_cyan}{folder_info['created']}{_reset}")
        print(f"{INDENT}Modified: {_cyan}{folder_info['modified']}{_reset}")
    else:
        print(f"{INDENT}Matching files: {_cyan}{folder_info['media_count']}{_reset}")


def print_files_info(files: List[FileItem], folder_info: Dict) -> None:
    """Print summary information about the list of FileItem objects."""
    total_files = len(files)
    valid_files = sum(1 for f in files if f.is_valid)
    invalid_files = total_files - valid_files
    folder_info['valid_files'] = valid_files
    folder_info['invalid_files'] = invalid_files
    if not QUIET_MODE:
        print(f"{_yellow}Files Summary:{_reset}")
        print(f"{INDENT}Total files analyzed: {_cyan}{total_files}{_reset}")
        print(f"{INDENT}Valid files: {_cyan}{valid_files}{_reset}")
        print(f"{INDENT}Invalid files: {_cyan}{invalid_files}{_reset}")
    if (VERBOSE_MODE or SHOW_FILES_ERRORS) and invalid_files > 0:
        print(f"{_yellow}Files with errors:{_reset}")
        for file in files:
            if not file.is_valid:
                print(f"{INDENT}{_cyan}{file.name_old}{_reset}: {_red}{file.error}{_reset}")


def print_file_info(file: FileItem) -> None:
    """Print detailed information about a FileItem."""
    print(f"{_yellow}File:{_reset} {_yellow}{file.name_old}{_reset}")
    for prop, value in file.__dict__.items():
        if prop == 'error' and value:
            print(f"{INDENT}{prop}: {_red}{value}{_reset}")
        elif prop == 'is_valid' and not value:
            print(f"{INDENT}{prop}: {_red}{value}{_reset}")
        elif value not in (None, "", [], {}):
            print(f"{INDENT}{prop}: {_cyan}{value}{_reset}")


def process_files(media_list: List[FileItem], folder_info: Dict) -> None:
    """Process and organize media files."""
    processed_files: list[str] = []
    skipped_files: list[str] = []
    created_dirs: list[str] = []
    item: int = 1
    total_items: int = folder_info['valid_files']
    print(f"{_yellow}{'Moving' if USE_SUBDIRS else 'Renaming'} files:{_reset}")
    for file in media_list:
        if file.is_valid:
            # Create target directory if needed
            if USE_SUBDIRS:
                target_dir = SOURCE_DIR / file.subdir
                if not target_dir.exists() and not TEST_MODE:
                    target_dir.mkdir(parents=True, exist_ok=True)
                    created_dirs.append(file.subdir)
            # Move/rename file
            target_path = file.get_new_path()
            if target_path.exists() and not OVERWRITE:
                file.error = "Target file already exists."
                skipped_files.append(file.name_old)
                continue
            if not TEST_MODE:
                try:
                    file.path_old.rename(target_path)
                except Exception as e:
                    file.error = f"Error moving file: {str(e)}"
                    skipped_files.append(file.name_old)
                    continue
            
            if VERBOSE_MODE:
                old = f"{_cyan}{file.name_old:<13}{_reset}"
                arr = f"{_yellow}→{_reset}"
                new = f"{_cyan}{target_path}{_reset}"
                exf = f"{file.exif_date if file.exif_date else 'EXIF data not found'}"
                print(f"{INDENT}{old} ({_cyan if file.exif_date else _red}{exf}{_reset}) {arr} {new}")
            else:
                percentage = (item / total_items) * 100
                msg = f"\r\033[K\r{INDENT}File {item} of {total_items}: {_cyan}{file.name_old}{_reset} ({percentage:.0f}%)"
                print(msg, end="", flush=True)
                time.sleep(0.2)  # Small delay to ensure the print updates correctly
            item += 1

            if not TEST_MODE:
                processed_files.append(file.name_old)
        else:
            if not TEST_MODE:
                skipped_files.append(file.name_old)
    
    if not VERBOSE_MODE:
        print(f"\r\033[K\r{INDENT}Done.")

    folder_info['processed_files'] = processed_files
    folder_info['skipped_files'] = skipped_files
    folder_info['created_dirs'] = created_dirs
    return None


class FileItem:
    """Class representing a media file with its properties."""
    # Attributes
    subdir: Path
    path_old: Path
    path: Path
    stem: str
    ext_old: str
    ext: str
    error: str = ""
    name_old: str
    name: str
    size: int
    readable: bool
    writable: bool
    prefix: str
    exif_date: datetime.datetime | None
    date_time: datetime.datetime
    exif_type: str | None
    is_valid: bool
    type: str

    def get_subdir(self) -> str | None:
        """Format a subdirectory name according to the provided template"""
        if not USE_SUBDIRS:
            return None
        if self.exif_date is not None:
            # Parse time_day_starts
            h, m, s = map(int, TIME_DAY_STARTS.split(':'))
            day_start_time = datetime.time(h, m, s)
            # Adjust date if time is before day_start_time
            target_date = self.date_time
            if target_date.time() < day_start_time:
                target_date = target_date - datetime.timedelta(days=1)
            # Format the folder name according to template
            if FOLDER_TEMPLATE == "YYYYMMDD":
                return target_date.strftime("%Y%m%d")
            elif FOLDER_TEMPLATE == "YYYY-MM-DD":
                return target_date.strftime("%Y-%m-%d")
            else:
                return target_date.strftime("%Y%m%d")  # Default format
        else:
            return FALLBACK_FOLDER
    
    def get_prefix(self) -> str:
        """Format a timestamp prefix according to the provided template"""
        if FILE_TEMPLATE == "YYYYMMDD-HHMMSS":
            return self.exif_date.strftime("%Y%m%d-%H%M%S")
        # Add more format options if needed
        return self.exif_date.strftime("%Y%m%d-%H%M%S")  # Default format

    def get_exif_date(self) -> datetime.datetime | None:
        """Extract creation date from EXIF data"""
        try:
            with exiftool.ExifToolHelper() as et:
                metadata = et.get_metadata(self.path_old)
                # Try different EXIF tags for date information
                for tag in EXIF_DATE_TAGS:
                    if tag in metadata[0]:
                        date_str = metadata[0][tag]
                        # Handle different date formats
                        if isinstance(date_str, str):
                            if ":" in date_str[:10] and date_str[4:5] == ":":  # Format: 2024:05:09 18:01:05
                                date_str = date_str.replace(":", "-", 2)
                            return datetime.datetime.strptime(date_str[:19], "%Y-%m-%d %H:%M:%S")
        except (KeyError, ValueError, IndexError) as e:
            self.error = f"Error extracting EXIF data: {str(e)}"
        except Exception as e:
            self.error = f"Unexpected error: {str(e)}"
        return None

    def get_exif_type(self) -> str | None:
        """Extract media type from EXIF data"""
        try:
            with exiftool.ExifToolHelper() as et:
                metadata = et.get_metadata(self.path_old)
                #print(metadata[0])
                if "File:MIMEType" in metadata[0]:
                    return metadata[0]["File:MIMEType"]
        except (KeyError, ValueError, IndexError) as e:
            self.error = f"Error extracting EXIF type: {str(e)}"
        except Exception as e:
            self.error = f"Unexpected error: {str(e)}"
        return None

    def get_new_name(self) -> str:
        name: str = ""
        if self.prefix:
            name += self.prefix + "-"
        if self.interfix:
            name += self.interfix + "-"
        return f"{name}{self.stem}.{self.ext}"
    
    def get_new_path(self) -> Path:
        if USE_SUBDIRS:
            return Path(SOURCE_DIR / self.subdir / self.name_new).absolute()
        else:
            return Path(SOURCE_DIR / self.name_new).absolute()
    
    def get_new_extension(self) -> str:
        """Get new file extension based on CHANGE_EXTENSIONS mapping."""
        ext = self.ext_old.lower() if NORMALIZE_EXT else self.ext_old
        ext = CHANGE_EXTENSIONS.get(ext, ext)
        return ext

    def __init__(self, path: Path):
        """Initialize FileItem with path and extract attributes."""
        self.is_valid = True # Assume valid until checks are done
        self.path_old = path.absolute()
        self.name_old = path.name
        self.stem = path.stem
        self.ext_old = path.suffix.lstrip(".")
        self.ext = self.get_new_extension()

        self.size = path.stat().st_size
        if self.size == 0:
            self.error = "File is empty."
            self.is_valid = False
            return

        self.readable = os.access(path, os.R_OK)
        if not self.readable:
            self.error = "File is not readable."
            self.is_valid = False
            return

        self.writable = os.access(path, os.W_OK)
        if not self.writable:
            self.error = "File is not writable."
            self.is_valid = False
            return
        
        self.exif_date = self.get_exif_date()
        if self.exif_date is None:
            self.error = "No EXIF date found."
            if not USE_FALLBACK_FOLDER:
                self.is_valid = False
                return

        if self.exif_date is not None:
            self.date_time = self.exif_date + datetime.timedelta(seconds=OFFSET)

        if self.exif_date and USE_PREFIX:
            self.prefix = self.get_prefix()
        else:
            self.prefix = ""

        self.interfix = INTERFIX if INTERFIX else ""

        self.exif_type = self.get_exif_type()
        self.type = self.exif_type.split("/")[0] if self.exif_type else "unknown"
        
        if USE_SUBDIRS:
            self.subdir = self.get_subdir()
        
        self.name_new = self.get_new_name()
        self.path_new = self.get_new_path()


def main() -> None:
    """Main function to organize media files."""
    init_colors()
    parse_args()
    check_conditions()
    print_header()
    file_list = get_file_list(Path(SOURCE_DIR))
    folder_info = get_folder_info(file_list)
    print_folder_info(folder_info)
    files = get_media_objects(file_list, folder_info)
    print_files_info(files, folder_info)
    if folder_info['valid_files'] == 0:
        print("No valid media files to process. Exiting.")
        sys.exit(0)
    if not prompt_user(folder_info):
        sys.exit(0)
    process_files(files, folder_info)
    print_footer(folder_info)

# Run the main function
if __name__ == "__main__":
    main()