#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sort photos into date-based folders by reading EXIF creation date.
Requires: ExifTool command-line tool and PyExifTool Python library.
Author: github.com/barabasz
Version: 0.21
"""

import os
import sys
import shutil
import datetime
import subprocess
import time
import argparse
from typing import Dict, List, Union
from pathlib import Path

# Parse command line arguments
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Organize photos into date-based folders by reading EXIF creation date.",
        epilog="Example: organize_photos.py -o 3600 --fallback-folder UNSORTED"
    )
    
    parser.add_argument("-o", "--offset", type=int, default=0,
                        help="Time offset in seconds to apply to EXIF dates")
    parser.add_argument("-f", "--fallback-folder", type=str,
                        help="Folder name for images without EXIF date")
    parser.add_argument("-t", "--timestamp-format", type=str,
                        help="Format for timestamp prefix (YYYYMMDD-HHMMSS)")
    parser.add_argument("-d", "--day-starts", type=str,
                        help="Time when the new day starts (HH:MM:SS)")
    parser.add_argument("-i", "--interfix", type=str,
                        help="Text to insert between timestamp prefix and original filename")
    parser.add_argument("-r", "--replace", action="store_true",
                        help="Replace (overwrite) existing files during move operation")
    parser.add_argument("--use-fallback", action="store_true",
                        help="Move files without date to fallback folder")
    parser.add_argument("--no-prefix", action="store_true",
                        help="Do not add timestamp prefix to filenames")
    parser.add_argument("--include-dotfiles", action="store_true",
                        help="Include files starting with a dot")
    
    return parser.parse_args()

# Check if Colorama is installed
try:
    from colorama import Fore, Back, Style
except ImportError:
    print("\033[0;31mColorama is not installed.\033[0m")
    print("Please install it using: \033[0;36mpip install colorama\033[0m")
    sys.exit(1)

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
SCRIPT_VERSION = "0.21"
IMG_EXTENSIONS = ['jpg', 'jpeg', 'dng', 'orf', 'ori', 'raw']
FALLBACK_FOLDER = "UNKNOWN_DATE"  # Folder for images without EXIF date
TIME_DAY_STARTS = "04:00:00"  # Time when the new day starts for photo grouping
FOLDER_TEMPLATE = "YYYYMMDD"  # Template for folder names
INCLUDE_DOTFILES = False  # Whether to include files starting with a dot
USE_FALLBACK_FOLDER = False  # Whether to move files without date to fallback folder
OVERWRITE = False  # Whether to overwrite existing files during move operation
ADD_TIMESTAMP_PREFIX = True  # Whether to add timestamp prefix to filenames
TIMESTAMP_PREFIX_FORMAT = "YYYYMMDD-HHMMSS"  # Format for timestamp prefix
OFFSET = 0  # Time offset in seconds to apply to EXIF dates
INTERFIX = "-"  # Text to insert between timestamp prefix and original filename
INDENT = "    "  # Indentation for printed messages

# Color definitions
cyan, green, red, reset, yellow, gray = "", "", "", "", "", ""

def init_colors() -> None:
    # Color definitions
    global cyan, green, red, reset, yellow, gray
    cyan = Fore.CYAN
    green = Fore.GREEN
    red = Fore.RED
    reset = Style.RESET_ALL
    yellow = Fore.YELLOW
    gray = Fore.LIGHTBLACK_EX
    return

def print_header(source_dir: Path) -> None:
    """Print script configuration header"""
    print(green + "Photo Organizer Script v" + SCRIPT_VERSION + reset)
    print(yellow + "Settings:" + reset)
    print(f"{INDENT}Working directory: {cyan}{source_dir}{reset}")
    print(f"{INDENT}Image extensions: {cyan}{', '.join(IMG_EXTENSIONS)}{reset}")
    print(f"{INDENT}Using subfolder template: {cyan}{FOLDER_TEMPLATE}{reset}")
    print(f"{INDENT}Day starts time set to: {cyan}{TIME_DAY_STARTS}{reset}")
    if USE_FALLBACK_FOLDER:
        print(f"{INDENT}Fallback folder name: {cyan}{FALLBACK_FOLDER}{reset}")
    if INCLUDE_DOTFILES:
        print(f"{INDENT}Include dotfiles: {cyan}{INCLUDE_DOTFILES}{reset}")
    if OVERWRITE:
        print(f"{INDENT}Overwrite existing files: {cyan}{OVERWRITE}{reset}")
    if ADD_TIMESTAMP_PREFIX:
        print(f"{INDENT}Timestamp prefix format: {cyan}{TIMESTAMP_PREFIX_FORMAT}{reset}")
    if OFFSET != 0:
        print(f"{INDENT}Time offset: {cyan}{OFFSET} seconds{reset}")
    if INTERFIX != "-":
        print(f"{INDENT}Interfix: {cyan}{INTERFIX}{reset}")
    return

def print_folder_info(file_count: int = 0, image_count: int = 0, image_types: Dict[str, int] = {}) -> None:
    """Print information about files in the working directory"""
    if file_count == 0:
        print(f"{red}No files found in the working directory.{reset}")
        sys.exit(1)
    if image_count == 0:
        print(f"{red}No image files found in the working directory.{reset}")
        sys.exit(1)
    print(yellow + "Directory:" + reset)
    print(f"{INDENT}Total files found: {cyan}{file_count}{reset}")
    print(f"{INDENT}Image files found: {cyan}{image_count}{reset}", end="")
    print(f" ({', '.join(f'{cyan}{count}{reset} x {cyan}{ext.upper()}{reset}' for ext, count in image_types.items())})")
    return

def print_footer(images_count: int, done_count: int, dirs_count: int, start_time: float) -> None:
    """Print summary of the operation"""
    elapsed_time: float = time.time() - start_time
    print(yellow + "Summary:" + reset)
    print(f"{INDENT}Total images processed: {cyan}{done_count}{reset}")
    images_skipped = images_count - done_count
    if images_skipped > 0:
        print(f"{INDENT}Files skipped: {red}{images_skipped}{reset}")
    if dirs_count > 0:
        print(f"{INDENT}Directories created: {cyan}{dirs_count}{reset}")
    print(f"{INDENT}Elapsed time: {cyan}{elapsed_time:.2f}{reset} seconds")
    return

def get_image_list(file_list: List[Path]) -> List[Path]:
    """Filter the list of files to only include images"""
    # Filter the list of files to only include images
    return [f for f in file_list if f.suffix.lstrip(".").lower() in IMG_EXTENSIONS]

def get_file_list(directory: Union[str, Path]) -> List[Path]:
    """Get a list of files in the specified directory"""
    # Convert to Path if it's a string
    if isinstance(directory, str):
        directory = Path(directory)
    # Get list of files in the directory matching the extensions
    file_list: List[Path] = []
    for f in directory.iterdir():
        if not f.is_file():
            continue
        # check permissions
        if not (os.access(f, os.R_OK) and os.access(f, os.W_OK)):
            continue
        # skip dotfiles
        if not INCLUDE_DOTFILES and f.name.startswith("."):
            continue
        file_list.append(f)
    file_list.sort(key=lambda p: str(p).lower())
    return file_list

def get_image_types(file_list: List[Path]) -> Dict[str, int]:
    """Get a count of image types in the file list"""
    image_types: Dict[str, int] = {}
    for f in file_list:
        ext = f.suffix.lstrip(".").lower()
        if ext in IMG_EXTENSIONS:
            image_types[ext] = image_types.get(ext, 0) + 1
    return image_types

def process_files(file_list: List[Path]) -> tuple[int, int]:
    """Process and move files based on EXIF date"""
    print(f"{yellow}Processing…{reset}")
    done_count: int = 0
    dirs_count: int = 0
    for file_path in file_list:
        file_name = file_path.name
        file_base = file_path.stem
        file_ext = file_path.suffix.lstrip(".").lower()
        file_ext = "jpg" if file_ext == "jpeg" else file_ext  # Normalize jpeg to jpg
        exif_date = get_exif_date(file_path)

        print(f"{INDENT}{gray}[{yellow}{file_ext.upper()}{gray}]{reset} {file_name} ", end="")

        if exif_date is None:
            print(f"({red}EXIF data not found{reset}) ", end="")
            if not USE_FALLBACK_FOLDER:
                print(f"{red}skipped{reset}: fallback folder disabled")
                continue
        else:
            print(f"({cyan}{exif_date}{reset}) ", end="")

        file_dir = file_path.parent
        file_prefix = get_file_prefix(exif_date) if ADD_TIMESTAMP_PREFIX else ""
        file_interfix = INTERFIX if ADD_TIMESTAMP_PREFIX and file_prefix else ""

        new_file_dir = get_new_file_dir(exif_date)
        dir_created = False
        if not new_file_dir.exists():
            if not (dir_created := create_directory(new_file_dir)):
                print(f"{red}skipped{reset}: failed to create directory {cyan}{new_file_dir}{reset}")
                continue
            dirs_count += 1
        new_file_name = f"{file_prefix}{file_interfix}{file_base}.{file_ext}"
        new_file_path = new_file_dir / new_file_name

        # Check if destination file exists
        if new_file_path.exists() and not OVERWRITE:
            print(f"{red}skipped{reset}: file already exists in {cyan}{new_file_dir}{reset}")
            continue
        
        # Try to move the file
        try:
            shutil.move(str(file_path), str(new_file_path))
            print(f"{yellow}→{reset} {green if dir_created else ''}{new_file_dir}{reset}/{cyan}{file_prefix}{file_interfix}{gray}{file_base}.{file_ext}{reset}")
            done_count += 1
        except Exception as e:
            print(f"{INDENT}{red}Error moving file {file_name} to {new_file_dir}: {str(e)}{reset}")
            continue

    return done_count, dirs_count

def get_exif_date(file_path: Path) -> Union[datetime.datetime, None]:
    """Extract creation date from EXIF data"""
    try:
        with exiftool.ExifToolHelper() as et:
            metadata = et.get_metadata(str(file_path))
            # Try different EXIF tags for date information
            for tag in ['EXIF:DateTimeOriginal', 'EXIF:CreateDate', 'XMP:CreateDate']:
                if tag in metadata[0]:
                    date_str = metadata[0][tag]
                    # Handle different date formats
                    if isinstance(date_str, str):
                        if ":" in date_str[:10] and date_str[4:5] == ":":  # Format: 2024:05:09 18:01:05
                            date_str = date_str.replace(":", "-", 2)
                        return datetime.datetime.strptime(date_str[:19], "%Y-%m-%d %H:%M:%S")
    except (KeyError, ValueError, IndexError) as e:
        print(f"Error extracting EXIF data from {file_path}: {str(e)}")
    except Exception as e:
        print(f"Unexpected error processing {file_path}: {str(e)}")
    return None

def get_file_prefix(date: Union[datetime.datetime, None]) -> str:
    """Get formatted timestamp prefix for filename"""
    if date is None:
        return ""
    date_with_offset = date
    if OFFSET != 0:
        date_with_offset = date + datetime.timedelta(seconds=OFFSET)
    return format_timestamp_prefix(date_with_offset, TIMESTAMP_PREFIX_FORMAT)

def format_timestamp_prefix(date: datetime.datetime, format_template: str) -> str:
    """Format a timestamp prefix according to the provided template"""
    if format_template == "YYYYMMDD-HHMMSS":
        return date.strftime("%Y%m%d-%H%M%S")
    # Add more format options if needed
    return date.strftime("%Y%m%d-%H%M%S")  # Default format

def get_new_file_dir(date: Union[datetime.datetime, None]) -> Path:
    """Get the target directory for the file based on its date"""
    if date is None:
        if USE_FALLBACK_FOLDER:
            target_folder = Path(FALLBACK_FOLDER)
        else:
            return Path.cwd()
    else:
        date_with_offset = date
        if OFFSET != 0:
            date_with_offset = date + datetime.timedelta(seconds=OFFSET)
        target_folder_name = get_target_folder_name(date_with_offset, TIME_DAY_STARTS, FOLDER_TEMPLATE)
        target_folder = Path(target_folder_name)
    return target_folder

def create_directory(path: Path) -> bool:
    """Create directory if it doesn't exist"""
    try:
        path.mkdir(parents=True, exist_ok=True)
        return True
    except Exception as e:
        print(f"{red}skipped: error creating directory {path}: {str(e)}{reset}")
        return False

def get_target_folder_name(date: datetime.datetime, time_day_starts: str, folder_template: str) -> str:
    """Determine the target folder name based on date and time_day_starts"""
    if date is None:
        return FALLBACK_FOLDER
    # Parse time_day_starts
    h, m, s = map(int, time_day_starts.split(':'))
    day_start_time = datetime.time(h, m, s)
    # Adjust date if time is before day_start_time
    target_date = date.date()
    if date.time() < day_start_time:
        target_date = target_date - datetime.timedelta(days=1)
    # Format the folder name according to template
    if folder_template == "YYYYMMDD":
        return target_date.strftime("%Y%m%d")
    elif folder_template == "YYYY-MM-DD":
        return target_date.strftime("%Y-%m-%d")
    else:
        return target_date.strftime("%Y%m%d")  # Default format

def main() -> None:
    ## Variables
    start_time: float = time.time()
    source_dir: Path = Path.cwd()
    
    # Parse command line arguments
    args = parse_args()
    
    # Update configuration based on command line arguments
    global FALLBACK_FOLDER, TIME_DAY_STARTS, INCLUDE_DOTFILES, USE_FALLBACK_FOLDER
    global OVERWRITE, ADD_TIMESTAMP_PREFIX, TIMESTAMP_PREFIX_FORMAT, OFFSET, INTERFIX
    
    if args.offset is not None:
        OFFSET = args.offset
    if args.fallback_folder:
        FALLBACK_FOLDER = args.fallback_folder
    if args.day_starts:
        TIME_DAY_STARTS = args.day_starts
    if args.timestamp_format:
        TIMESTAMP_PREFIX_FORMAT = args.timestamp_format
    if args.interfix:
        INTERFIX = args.interfix
    if args.replace:
        OVERWRITE = True
    if args.use_fallback:
        USE_FALLBACK_FOLDER = True
    if args.no_prefix:
        ADD_TIMESTAMP_PREFIX = False
    if args.include_dotfiles:
        INCLUDE_DOTFILES = True
    
    file_list: List[Path] = []
    image_list: List[Path] = []
    image_types: Dict[str, int] = {}
    file_count: int = 0
    image_count: int = 0
    done_count: int = 0
    dirs_count: int = 0
    
    ## Main script execution
    # Initialize colors and print header
    init_colors()
    print_header(source_dir)
    
    # Get file and image lists
    file_list = get_file_list(source_dir)
    file_count = len(file_list)
    image_list = get_image_list(file_list)
    image_count = len(image_list)
    image_types = get_image_types(file_list)
    
    # Print folder info
    print_folder_info(file_count, image_count, image_types)
    
    # Process image files
    done_count, dirs_count = process_files(image_list)
    
    # Print footer summary
    print_footer(image_count, done_count, dirs_count, start_time)
    return

if __name__ == "__main__":
    main()