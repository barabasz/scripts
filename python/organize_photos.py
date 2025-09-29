#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sort photos into date-based folders by reading EXIF creation date.
Requires: ExifTool command-line tool and PyExifTool Python library.
Version: 0.17
"""

import os
import sys
import shutil
import datetime
import subprocess
from pathlib import Path

# Check if Colorama is installed
try:
    from colorama import init, Fore, Back, Style
except ImportError:
    print("Colorama is not installed.")
    print("Please install it using: pip install colorama")
    sys.exit(1)
init(autoreset=True)

# Check if PyExifTool is installed
try:
    import exiftool
except ImportError:
    print(Fore.RED + "PyExifTool is not installed.")
    print("Please install it using: pip install PyExifTool")
    sys.exit(1)

# Check if ExifTool command-line tool is available
try:
    subprocess.run(['exiftool', '-ver'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
except (subprocess.SubprocessError, FileNotFoundError):
    print(Fore.RED + "ExifTool command-line tool is not installed or not in PATH.")
    print("Please download and install it from: https://exiftool.org/")
    sys.exit(1)

# Configuration variables
IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'dng', 'orf', 'raw']
FALLBACK_FOLDER = "unknown_date"  # Folder for images without EXIF date
TIME_DAY_STARTS = "04:00:00"  # Time when the new day starts for photo grouping
FOLDER_TEMPLATE = "YYYYMMDD"  # Template for folder names
INCLUDE_DOTFILES = False  # Whether to include files starting with a dot
USE_FALLBACK_FOLDER = False  # Whether to move files without date to fallback folder
OVERWRITE = False  # Whether to overwrite existing files during move operation

# Color definitions
yellow = Fore.YELLOW
green = Fore.GREEN
cyan = Fore.CYAN
reset = Style.RESET_ALL
red = Fore.RED

def print_header(directory):
    """Print script configuration header"""
    print(yellow + "Settings:" + reset)
    print(f"Processing directory: {cyan}{directory}{reset}")
    print(f"Day starts time set to: {cyan}{TIME_DAY_STARTS}{reset}")
    print(f"Using folder template: {cyan}{FOLDER_TEMPLATE}{reset}")
    print(f"Image extensions: {cyan}{', '.join(IMAGE_EXTENSIONS)}{reset}")
    print(f"Fallback folder name: {cyan}{FALLBACK_FOLDER}{reset}")
    print(f"Include dotfiles: {cyan}{INCLUDE_DOTFILES}{reset}")
    print(f"Use fallback folder: {cyan}{USE_FALLBACK_FOLDER}{reset}")
    print(f"Overwrite existing files: {cyan}{OVERWRITE}{reset}")
    print(yellow + "Output:" + reset)

def print_summary(total_files, image_files, files_moved_to_date, files_moved_to_fallback, created_folders):
    """Print summary of the operation"""
    print(yellow + "Summary:" + reset)
    print(f"Total files found: {green}{total_files}{reset}")
    print(f"Image files found: {green}{image_files}{reset}")
    print(f"Files moved to date folders: {green}{files_moved_to_date}{reset}")
    print(f"Files moved to fallback folder: {green}{files_moved_to_fallback}{reset}")
    print(f"Folders created: {green}{created_folders}{reset}")

def get_exif_date(file_path):
    """Extract creation date from EXIF data"""
    try:
        with exiftool.ExifToolHelper() as et:
            metadata = et.get_metadata(str(file_path))
            
            # Try different EXIF tags for date information
            for tag in ['EXIF:DateTimeOriginal', 'EXIF:CreateDate', 'XMP:CreateDate', 
                        'QuickTime:CreationDate', 'File:FileModifyDate']:
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

def get_target_folder(date, time_day_starts, folder_template):
    """Determine the target folder based on date and time_day_starts"""
    if date is None:
        return None
        
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

def main():
    # Get current directory
    directory = os.getcwd()
    print_header(directory)
    
    # Initialize counters
    total_files = 0
    image_files = 0
    files_moved_to_date = 0
    files_moved_to_fallback = 0
    created_folders = set()
    
    # Process each file in the directory
    for item in os.listdir(directory):
        # Skip directories
        if os.path.isdir(os.path.join(directory, item)):
            continue
        
        # Skip hidden files if not included
        if not INCLUDE_DOTFILES and item.startswith('.'):
            continue
            
        total_files += 1
        file_path = os.path.join(directory, item)
        _, ext = os.path.splitext(item)
        ext = ext.lstrip('.')
        
        # Check if the file is an image
        if ext.lower() not in [x.lower() for x in IMAGE_EXTENSIONS]:
            continue
            
        image_files += 1
        
        # Get creation date from EXIF
        date = get_exif_date(file_path)
        
        # Determine target folder
        if date:
            folder_name = get_target_folder(date, TIME_DAY_STARTS, FOLDER_TEMPLATE)
            date_str = date.strftime("%Y-%m-%d @ %H:%M:%S")
        else:
            if not USE_FALLBACK_FOLDER:
                print(f"Skipped {item} (no date found)")
                continue
                
            folder_name = FALLBACK_FOLDER
            date_str = "no date found"
        
        # Create target folder if it doesn't exist
        target_folder = os.path.join(directory, folder_name)
        if not os.path.exists(target_folder):
            os.makedirs(target_folder)
            created_folders.add(folder_name)
        
        # Move the file to the target folder
        target_file = os.path.join(target_folder, item)
        if os.path.exists(target_file) and not OVERWRITE:
            print(f"Skipped {item} ({date_str}) - file already exists in {folder_name}/")
            continue
            
        try:
            shutil.move(file_path, target_file)
            print(f"Moved {item} ({date_str}) to {folder_name}/")
            
            if folder_name == FALLBACK_FOLDER:
                files_moved_to_fallback += 1
            else:
                files_moved_to_date += 1
                
        except Exception as e:
            print(f"Error moving {item} to {folder_name}/: {str(e)}")
    
    # Print summary

    if image_files > 0:
        print_summary(total_files, image_files, files_moved_to_date, 
                     files_moved_to_fallback, len(created_folders))
    else:
        print(red + "No image files found to process." + reset)

if __name__ == "__main__":
    main()