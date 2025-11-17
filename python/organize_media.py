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

# Import Config class
try:
    from config import Config
except ImportError:
    print("\033[0;31mConfig module not found.\033[0m")
    print("Please ensure config.py is in the same directory or in your Python path.")
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


# Global config instance (initialized in main)
cfg = None


def init_config() -> Config:
    """
    Initialize configuration with default values.
    
    Returns:
        Config instance with all default settings.
    """
    return Config(
        # Script metadata (read-only)
        script_name=(str, "organize_media", True),
        script_version=(str, "0.55", True),
        script_date=(str, "2025-11-17", True),
        script_author=(str, "github.com/barabasz", True),
        
        # File processing settings (read-only defaults)
        extensions=(list, ['jpg', 'jpeg', 'dng', 'mov', 'mp4', 'orf', 'ori', 'raw']),
        change_extensions=(dict, {'jpeg': 'jpg', 'tiff': 'tif'}, True),
        exif_date_tags=(list, [
            'EXIF:DateTimeOriginal',
            'EXIF:CreateDate',
            'XMP:CreateDate',
            'QuickTime:CreateDate'
        ], True),
        
        # Folder/file naming templates
        fallback_folder=(str, "_UNKNOWN"),
        file_template=(str, "YYYYMMDD-HHMMSS"),
        folder_template=(str, "YYYYMMDD"),
        interfix=(str, ""),
        
        # Display settings
        indent=(str, "    ", True),
        
        # Behavior flags
        normalize_ext=(bool, True),
        offset=(int, 0),
        overwrite=(bool, False),
        quiet_mode=(bool, False),
        show_version=(bool, False),
        show_files_details=(bool, False),
        show_files_errors=(bool, False),
        show_raw_settings=(bool, False),
        test_mode=(bool, False),
        time_day_starts=(str, "04:00:00"),
        use_fallback_folder=(bool, False),
        use_prefix=(bool, True),
        use_subdirs=(bool, True),
        verbose_mode=(bool, False),
        yes_to_all=(bool, False),
        
        # Runtime values
        source_dir=(Path, Path.cwd()),
        source_dir_writable=(bool, False),
    )


def parse_args() -> None:
    """Parse command line arguments and update configuration."""
    
    parser = argparse.ArgumentParser(
        prog=cfg.script_name,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Organize media files into date-based folders by reading EXIF creation date.\n" \
        f"Requires {_green}ExifTool{_reset} command-line tool and {_green}PyExifTool{_reset} Python library.\n" \
        f"Default schema: {get_schema()}",
        epilog=f"Example: {_green}{cfg.script_name}{_reset} -o 3600 --fallback-folder UNSORTED"
    )
    
    # Options with arguments - use cfg.* as defaults
    parser.add_argument("-d", "--directory-template", type=str, default=cfg.folder_template, metavar="TEMPLATE",
                        help=f"Template for directory names (default: '{_yellow}{cfg.folder_template}{_reset}')")
    parser.add_argument("-D", "--files-details", action="store_true",
                        help="Show detailed information about each file")
    parser.add_argument("-e", "--extensions", type=str, nargs="+", default=cfg.extensions, metavar="EXT",
                        help=f"List of file extensions to process (default: '{_yellow}{', '.join(cfg.extensions)}{_reset}')")
    parser.add_argument("-E", "--show-errors", action="store_true",
                        help="Show files with errors")
    parser.add_argument("-f", "--file-template", type=str, default=cfg.file_template, metavar="TEMPLATE",
                        help=f"Template for file names (default: '{_yellow}{cfg.file_template}{_reset}')")
    parser.add_argument("-i", "--interfix", type=str, default=cfg.interfix, metavar="TEXT",
                        help=f"Text to insert between timestamp prefix and original filename (default: '{_yellow}-{_reset}')")
    parser.add_argument("-n", "--new-day", type=str, default=cfg.time_day_starts, metavar="HH:MM:SS",
                        help=f"Time when the new day starts (default: '{_yellow}{cfg.time_day_starts}{_reset}')")
    parser.add_argument("-N", "--no-normalize", action="store_false", dest="normalize_ext",
                        help="Do not normalize extensions to 3-letter lowercase")
    parser.add_argument("-F", "--fallback-folder", type=str, default=cfg.fallback_folder, metavar="FOLDER",
                        help=f"Folder name for images without EXIF date (default: '{_yellow}{cfg.fallback_folder}{_reset}')")
    parser.add_argument("-o", "--offset", type=int, default=cfg.offset, metavar="SECONDS",
                        help="Time offset in seconds to apply to EXIF dates")
    parser.add_argument("-O", "--overwrite", action="store_true",
                        help="Overwrite existing files during move/rename operation")
    parser.add_argument("-p", "--no-prefix", action="store_false", dest="use_prefix",
                        help="Do not add timestamp prefix to filenames")
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Quiet mode (suppress non-error messages)")
    parser.add_argument("-s", "--skip-fallback", action="store_true",
                        help="Do not move files without date to fallback folder")
    parser.add_argument("-S", "--settings", action="store_true",
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
    parser.add_argument("directory", type=str, default=str(cfg.source_dir), nargs="?",
                    help="Directory to organize (default: current working directory)")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Update ONLY the values that were actually provided or changed
    cfg.extensions = [ext.lower().lstrip('.') for ext in args.extensions]
    cfg.fallback_folder = args.fallback_folder
    cfg.file_template = args.file_template
    cfg.folder_template = args.directory_template
    cfg.interfix = args.interfix
    cfg.normalize_ext = args.normalize_ext
    cfg.offset = args.offset
    cfg.overwrite = args.overwrite
    cfg.quiet_mode = args.quiet
    cfg.show_version = args.version
    cfg.show_files_details = args.files_details
    cfg.show_files_errors = args.show_errors
    cfg.show_raw_settings = args.settings
    cfg.source_dir = Path(args.directory).resolve()
    cfg.source_dir_writable = os.access(cfg.source_dir, os.W_OK)
    cfg.test_mode = args.test
    cfg.time_day_starts = args.new_day
    cfg.use_fallback_folder = not args.skip_fallback
    cfg.use_prefix = args.use_prefix
    cfg.use_subdirs = args.use_subdirs
    cfg.verbose_mode = args.verbose
    cfg.yes_to_all = args.yes


def printe(message: str, exit_code: int = 1) -> None:
    """Print and exit."""
    msg: str = message if exit_code == 0 else f"{_red}Error{_reset}: {message}"
    print(msg)
    sys.exit(exit_code)


def check_conditions() -> None:
    """Validate command line arguments and exit if invalid."""
    msg: str = ""
    code: int = 0

    if cfg.show_version:
        msg = f"{_green}{cfg.script_name}{_reset} version {_cyan}{cfg.script_version}{_reset} ({cfg.script_date}) by {_cyan}{cfg.script_author}{_reset}"
    if not cfg.source_dir.is_dir():
        dir_path: str = f"{_cyan}{cfg.source_dir}{_reset}"
        msg = f"The specified directory '{dir_path}' does not exist or is not a directory."
        code = 1
    elif not cfg.source_dir_writable:
        dir_path: str = f"{_cyan}{cfg.source_dir}{_reset}"
        msg = f"The specified directory '{dir_path}' is not writable."
        code = 1
    if not cfg.extensions or all(ext.strip() == "" for ext in cfg.extensions):
        msg = f"At least one file extension must be specified."
        code = 1
    if cfg.quiet_mode and cfg.verbose_mode:
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
    folder: str = f"{_cyan}{cfg.folder_template}{_reset}"
    folder = f"{folder}/" if cfg.use_subdirs else ""
    prefix: str = f"{_cyan}{cfg.file_template}{_reset}"
    separator: str = f"{_cyan}{cfg.interfix}{_reset}"
    file_new: str = file_org.lower() if cfg.normalize_ext else file_org
    if cfg.use_prefix:
        separator = f"-{cfg.interfix}-" if cfg.interfix != "" else "-"
        file_new = f"{prefix}{separator}{file_new}"
    return f"{file_org} {arrow} {folder}{file_new}"


def print_schema() -> None:
    """Print the current schema."""
    print(f"{_yellow}Schema:{_reset}")
    print(f"{cfg.indent}{get_schema()}")


def print_settings() -> None:
    """Print current settings."""
    print(f"{_yellow}RAW Settings:{_reset}")
    print(f"{cfg.indent}change_extensions: {_cyan}{cfg.change_extensions}{_reset}")
    print(f"{cfg.indent}exif_date_tags: {_cyan}{cfg.exif_date_tags}{_reset}")
    print(f"{cfg.indent}extensions: {_cyan}{cfg.extensions}{_reset}")
    print(f"{cfg.indent}fallback_folder: {_cyan}{cfg.fallback_folder}{_reset}")
    print(f"{cfg.indent}file_template: {_cyan}{cfg.file_template}{_reset}")
    print(f"{cfg.indent}folder_template: {_cyan}{cfg.folder_template}{_reset}")
    print(f"{cfg.indent}interfix: {_cyan}{cfg.interfix}{_reset}")
    print(f"{cfg.indent}normalize_ext: {_cyan}{cfg.normalize_ext}{_reset}")
    print(f"{cfg.indent}offset: {_cyan}{cfg.offset}{_reset}")
    print(f"{cfg.indent}overwrite: {_cyan}{cfg.overwrite}{_reset}")
    print(f"{cfg.indent}quiet_mode: {_cyan}{cfg.quiet_mode}{_reset}")
    print(f"{cfg.indent}show_version: {_cyan}{cfg.show_version}{_reset}")
    print(f"{cfg.indent}show_files_details: {_cyan}{cfg.show_files_details}{_reset}")
    print(f"{cfg.indent}show_raw_settings: {_cyan}{cfg.show_raw_settings}{_reset}")
    print(f"{cfg.indent}source_dir: {_cyan}{cfg.source_dir}{_reset}")
    print(f"{cfg.indent}source_dir_writable: {_cyan}{cfg.source_dir_writable}{_reset}")
    print(f"{cfg.indent}test_mode: {_cyan}{cfg.test_mode}{_reset}")
    print(f"{cfg.indent}time_day_starts: {_cyan}{cfg.time_day_starts}{_reset}")
    print(f"{cfg.indent}use_fallback_folder: {_cyan}{cfg.use_fallback_folder}{_reset}")
    print(f"{cfg.indent}use_prefix: {_cyan}{cfg.use_prefix}{_reset}")
    print(f"{cfg.indent}use_subdirs: {_cyan}{cfg.use_subdirs}{_reset}")
    print(f"{cfg.indent}verbose_mode: {_cyan}{cfg.verbose_mode}{_reset}")
    print(f"{cfg.indent}yes_to_all: {_cyan}{cfg.yes_to_all}{_reset}")


def print_header() -> None:
    """Print script header with version information."""
    global start_time
    start_time = time.time()
    on = f"{_green}ON{_reset}"
    off = f"{_red}OFF{_reset}"
    print(f"{_green}Media Organizer Script{_reset} ({_green}{cfg.script_name}{_reset}) v{cfg.script_version}{_reset}")
    if cfg.show_raw_settings and not cfg.quiet_mode:
        print_settings()
    print_schema()
    if cfg.quiet_mode:
        return
    print(f"{_yellow}Settings:{_reset}")
    if cfg.verbose_mode:
        print(f"{cfg.indent}Verbose mode: {on if cfg.verbose_mode else off}")
    if cfg.test_mode or cfg.verbose_mode:
        print(f"{cfg.indent}Test mode: {on if cfg.test_mode else off}")
    if cfg.extensions:
        print(f"{cfg.indent}Include extensions: {_cyan}{', '.join(cfg.extensions)}{_reset}")
    if cfg.verbose_mode or not cfg.use_subdirs:
        print(f"{cfg.indent}Process to subdirectories: {on if cfg.use_subdirs else off}")
    if cfg.use_subdirs:
        print(f"{cfg.indent}Subfolder template: {_cyan}{cfg.folder_template}{_reset}")
    if cfg.verbose_mode or cfg.time_day_starts != "00:00:00":
        print(f"{cfg.indent}Day starts time set to: {_cyan}{cfg.time_day_starts}{_reset}")
    if cfg.verbose_mode or cfg.overwrite:
        print(f"{cfg.indent}Overwrite existing files: {on if cfg.overwrite else off}")
    if cfg.verbose_mode or not cfg.normalize_ext:
        print(f"{cfg.indent}Normalize extensions: {on if cfg.normalize_ext else off}")
    if cfg.verbose_mode or not cfg.use_prefix:
        print(f"{cfg.indent}Add prefix to filenames: {on if cfg.use_prefix else off}")
    if cfg.verbose_mode or cfg.use_prefix:
        print(f"{cfg.indent}Prefix format: {_cyan}{cfg.file_template}{_reset}")
    if cfg.verbose_mode or not cfg.use_fallback_folder:
        print(f"{cfg.indent}Use fallback folder: {on if cfg.use_fallback_folder else off}")
    if cfg.use_fallback_folder:
        print(f"{cfg.indent}Fallback folder name: {_cyan}{cfg.fallback_folder}{_reset}")
    if cfg.verbose_mode or cfg.offset != 0:
        print(f"{cfg.indent}Time offset: {_cyan}{cfg.offset} seconds{_reset}")
    if cfg.interfix or cfg.verbose_mode:
        print(f"{cfg.indent}Interfix: {_cyan}{cfg.interfix}{_reset}")


def get_elapsed_time() -> tuple[str, str]:
    """Get elapsed time since script start in milliseconds."""
    elapsed_time: float = (time.time() - start_time) * 1000
    time_factor: str = "ms" if elapsed_time < 1000 else "s"
    elapsed_time = elapsed_time / 1000 if elapsed_time >= 1000 else elapsed_time
    return f"{elapsed_time:.2f}", time_factor


def print_footer(folder_info: Dict) -> None:
    """Print script footer."""
    time_elapsed, time_factor = get_elapsed_time()
    print(f"{_yellow}Summary:{_reset}")
    if cfg.test_mode:
        print(f"{cfg.indent}Test mode (no changes made).")
    else:
        print(f"{cfg.indent}Processed files: {len(folder_info['processed_files'])}")
        print(f"{cfg.indent}Skipped files: {len(folder_info['skipped_files'])}")
        print(f"{cfg.indent}Directories created: {len(folder_info['created_dirs'])}")
    print(f"{cfg.indent}Completed in: {_cyan}{time_elapsed}{_reset} {time_factor}.{_reset}")


def prompt_user(folder_info: Dict[str, int]) -> bool:
    """Ask user for confirmation to continue."""
    if cfg.yes_to_all or cfg.test_mode:
        return True
    prompt = f"{_yellow}Do you want to continue with {folder_info['valid_files']} files? (yes/No): {_reset}"
    answer = input(prompt).strip().lower()
    if answer not in ('y', 'yes'):
        print("Operation cancelled by user.")
        return False
    return True


def get_media_objects(file_list: list[Path], folder_info: Dict) -> list['FileItem']:
    """Convert list of Paths to list of FileItem objects."""
    media_count = folder_info.get('media_count', 0)
    media_objects = []
    item: int = 1
    print(f"{_yellow}Analyzing files:{_reset}")
    for file in file_list:
        if file.suffix.lstrip('.').lower() in cfg.extensions:
            media_item = FileItem(file)
            percentage = (item / media_count) * 100
            if cfg.show_files_details and not cfg.quiet_mode:
                print_file_info(media_item)
            else:
                msg = f"\r\033[K\r{cfg.indent}File {item} of {media_count}: {_cyan}{media_item.name_old}{_reset} ({percentage:.0f}%)"
                print(msg, end="", flush=True)
            media_objects.append(media_item)
            item += 1
    if not cfg.show_files_details:
        print(f"\r\033[K\r{cfg.indent}Completed.")
    return media_objects


def get_file_list(directory: Path) -> list[Path]:
    """Get a sorted list of file Paths in the specified directory."""
    files = [directory / file for file in os.listdir(directory) if (directory / file).is_file()]
    return sorted(files, key=lambda x: x.name.lower())


def get_folder_info(file_list: list[Path]) -> Dict[str, int | float | str | set | Dict[str, int]]:
    """Get information about the folder."""
    info: Dict[str, int | float | str | set | Dict[str, int]] = {}
    info["path"] = cfg.source_dir
    info["created"] = datetime.datetime.fromtimestamp(cfg.source_dir.stat().st_ctime).strftime("%Y-%m-%d %H:%M:%S")
    info["modified"] = datetime.datetime.fromtimestamp(cfg.source_dir.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
    info["file_count"] = len(file_list)
    info["media_count"] = sum(1 for file in file_list if file.suffix.lstrip('.').lower() in cfg.extensions)
    media_types: Dict[str, int] = {}
    for f in file_list:
        ext = f.suffix.lstrip(".").lower()
        if ext in cfg.extensions:
            media_types[ext] = media_types.get(ext, 0) + 1
    info["media_types"] = media_types
    info['processed_files'] = []
    info['skipped_files'] = []
    info['created_dirs'] = []
    return info


def print_folder_info(folder_info: Dict) -> None:
    """Print information about the folder and media files."""
    print(f"{_yellow}Folder info:{_reset}")
    print(f"{cfg.indent}Path: {_cyan}{cfg.source_dir}{_reset}")
    print(f"{cfg.indent}Total files: {_cyan}{folder_info['file_count']}{_reset}")
    if cfg.verbose_mode:
        print(f"{cfg.indent}Matching files: {_cyan}{folder_info['media_count']}{_reset}", end="")
        print(f" ({', '.join(f'{_cyan}{count}{_reset} x {_cyan}{ext.upper()}{_reset}' for ext, count in folder_info['media_types'].items())})")
        print(f"{cfg.indent}Created: {_cyan}{folder_info['created']}{_reset}")
        print(f"{cfg.indent}Modified: {_cyan}{folder_info['modified']}{_reset}")
    else:
        print(f"{cfg.indent}Matching files: {_cyan}{folder_info['media_count']}{_reset}")


def print_invalid_files(files: List['FileItem']) -> None:
    """Print files not valid."""
    print(f"{_yellow}Files not valid:{_reset}")
    for file in files:
        if not file.is_valid:
            print(f"{cfg.indent}{_cyan}{file.name_old}{_reset}: {_red}{file.error}{_reset}")


def print_files_errors(files: List['FileItem']) -> None:
    """Print files with errors."""
    print(f"{_yellow}Files with errors:{_reset}")
    for file in files:
        if file.is_valid and file.error:
            print(f"{cfg.indent}{_cyan}{file.name_old}{_reset}: {_red}{file.error}{_reset}")


def print_files_info(files: List['FileItem'], folder_info: Dict) -> None:
    """Print summary information about the list of FileItem objects."""
    total_files = len(files)
    valid_files = sum(1 for f in files if f.is_valid)
    invalid_files = total_files - valid_files
    folder_info['valid_files'] = valid_files
    folder_info['invalid_files'] = invalid_files
    if not cfg.quiet_mode:
        print(f"{_yellow}Files Summary:{_reset}")
        print(f"{cfg.indent}Total files analyzed: {_cyan}{total_files}{_reset}")
        print(f"{cfg.indent}Valid files: {_cyan}{valid_files}{_reset}")
        print(f"{cfg.indent}Invalid files: {_cyan}{invalid_files}{_reset}")
    if (cfg.verbose_mode or cfg.show_files_errors) and invalid_files > 0:
        print_invalid_files(files)


def print_file_info(file: 'FileItem') -> None:
    """Print detailed information about a FileItem."""
    print(f"{_yellow}File:{_reset} {_yellow}{file.name_old}{_reset}")
    for prop, value in file.__dict__.items():
        if prop == 'error' and value:
            print(f"{cfg.indent}{prop}: {_red}{value}{_reset}")
        elif prop == 'is_valid' and not value:
            print(f"{cfg.indent}{prop}: {_red}{value}{_reset}")
        elif prop != 'metadata' and value not in (None, "", [], {}):
            print(f"{cfg.indent}{prop}: {_cyan}{value}{_reset}")


def print_process_file(file: 'FileItem', item: int, total_items: int) -> None:
    """Print information about a file being processed."""
    if cfg.verbose_mode:
        old = f"{_cyan}{file.name_old:<13}{_reset}"
        arr = f"{_yellow}→{_reset}"
        sub = f"{_cyan}{file.subdir}{_reset}/" if cfg.use_subdirs else ""
        new = f"{_cyan}{file.name_new}{_reset}"
        exf = f"{file.exif_date if file.exif_date else 'EXIF data not found'}"
        print(f"{cfg.indent}{old} ({_cyan if file.exif_date else _red}{exf}{_reset}) {arr} {sub}{new}")
    else:
        per = (item / total_items) * 100
        itm = f"{_cyan}{file.name_old}{_reset}"
        cls = "\r\033[K\r"
        msg = f"{cls}{cfg.indent}File {item} of {total_items}: {itm} ({per:.0f}%)"
        print(msg, end="", flush=True)


def process_files(media_list: List['FileItem'], folder_info: Dict) -> None:
    """Process and organize media files."""
    processed_files: list[str] = []
    skipped_files: list[str] = []
    created_dirs: list[str] = []
    item: int = 1
    total_items: int = folder_info['valid_files']
    print(f"{_yellow}{'Moving' if cfg.use_subdirs else 'Renaming'} files:{_reset}")
    for file in media_list:
        if file.is_valid:
            # Create target directory if needed
            if cfg.use_subdirs:
                target_dir = cfg.source_dir / file.subdir
                if not target_dir.exists() and not cfg.test_mode:
                    target_dir.mkdir(parents=True, exist_ok=True)
                    created_dirs.append(file.subdir)
            # Move/rename file
            if file.path_new.exists() and not cfg.overwrite:
                file.error = "Target file already exists."
                skipped_files.append(file.name_old)
                continue
            if not cfg.test_mode:
                try:
                    file.path_old.rename(file.path_new)
                except Exception as e:
                    file.error = f"Error moving file: {str(e)}"
                    skipped_files.append(file.name_old)
                    continue
            # Print process information
            print_process_file(file, item, total_items)
            item += 1
            processed_files.append(file.name_old)
        else:
            skipped_files.append(file.name_old)
    
    processed_files_count = len(processed_files)

    if not cfg.verbose_mode and processed_files_count > 0:
        print(f"\r\033[K\r{cfg.indent}Done.")
    if processed_files_count == 0 and not cfg.quiet_mode:
        print(f"{cfg.indent}No files were processed.")

    # Print files with errors if any
    if (cfg.verbose_mode or cfg.show_files_errors) and len(skipped_files) > 0:
        print_files_errors(media_list)

    folder_info['processed_files'] = processed_files
    folder_info['skipped_files'] = skipped_files
    folder_info['created_dirs'] = created_dirs
    return None


class FileItem:
    """Class representing a media file with its properties."""
    
    def get_subdir(self) -> str | None:
        """Format a subdirectory name according to the provided template"""
        if not cfg.use_subdirs:
            return None
        if self.exif_date is not None:
            # Parse time_day_starts
            h, m, s = map(int, cfg.time_day_starts.split(':'))
            day_start_time = datetime.time(h, m, s)
            # Adjust date if time is before day_start_time
            target_date = self.date_time
            if target_date.time() < day_start_time:
                target_date = target_date - datetime.timedelta(days=1)
            # Format the folder name according to template
            if cfg.folder_template == "YYYYMMDD":
                return target_date.strftime("%Y%m%d")
            elif cfg.folder_template == "YYYY-MM-DD":
                return target_date.strftime("%Y-%m-%d")
            else:
                return target_date.strftime("%Y%m%d")  # Default format
        else:
            return cfg.fallback_folder
    
    def get_prefix(self) -> str:
        """Format a timestamp prefix according to the provided template"""
        if cfg.file_template == "YYYYMMDD-HHMMSS":
            return self.date_time.strftime("%Y%m%d-%H%M%S")
        return self.date_time.strftime("%Y%m%d-%H%M%S")  # Default format

    def read_exif_metadata(self) -> bool:
        """Read all EXIF metadata at once and store it"""
        try:
            with exiftool.ExifToolHelper() as et:
                self.metadata = et.get_metadata(self.path_old)[0]
                return True
        except Exception as e:
            self.error = f"Error reading EXIF metadata: {str(e)}"
            return False
    
    def get_exif_date(self) -> datetime.datetime | None:
        """Extract creation date from stored EXIF data"""
        if not self.metadata:
            return None
        
        try:
            # Try different EXIF tags for date information
            for tag in cfg.exif_date_tags:
                if tag in self.metadata:
                    date_str = self.metadata[tag]
                    # Handle different date formats
                    if isinstance(date_str, str):
                        if ":" in date_str[:10] and date_str[4:5] == ":":
                            date_str = date_str.replace(":", "-", 2)
                        return datetime.datetime.strptime(date_str[:19], "%Y-%m-%d %H:%M:%S")
        except (KeyError, ValueError, IndexError) as e:
            self.error = f"Error extracting EXIF date: {str(e)}"
        return None

    def get_exif_type(self) -> str | None:
        """Extract media type from stored EXIF data"""
        if not self.metadata:
            return None
            
        try:
            if "File:MIMEType" in self.metadata:
                return self.metadata["File:MIMEType"]
        except Exception as e:
            self.error = f"Error extracting EXIF type: {str(e)}"
        return None

    def get_new_name(self) -> str:
        """Generate new filename based on prefix, interfix, stem, and extension."""
        name: str = ""
        if self.prefix:
            name += self.prefix + "-"
        if self.interfix:
            name += self.interfix + "-"
        return f"{name}{self.stem}.{self.ext_new}"
    
    def get_new_path(self) -> Path:
        """Get new absolute path for the file based on settings."""
        if cfg.use_subdirs:
            return Path(cfg.source_dir / self.subdir / self.name_new).absolute()
        else:
            return Path(cfg.source_dir / self.name_new).absolute()
    
    def get_new_extension(self) -> str:
        """Get new file extension based on change_extensions mapping."""
        ext = self.ext_old.lower() if cfg.normalize_ext else self.ext_old
        ext = cfg.change_extensions.get(ext, ext)
        return ext

    def __init__(self, path: Path):
        """Initialize FileItem with path and extract attributes."""
        self.is_valid = True
        self.path_old = path.absolute()
        self.name_old = path.name
        self.stem = path.stem
        self.ext_old = path.suffix.lstrip(".")
        self.ext_new = self.get_new_extension()
        self.error = ""
        self.metadata = None

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

        # Read EXIF metadata
        if not self.read_exif_metadata():
            self.is_valid = False
            return

        self.exif_date = self.get_exif_date()
        if self.exif_date is None:
            self.error = "No EXIF date found."
            if not cfg.use_fallback_folder:
                self.is_valid = False
                return

        if self.exif_date is not None:
            self.date_time = self.exif_date + datetime.timedelta(seconds=cfg.offset)

        if self.exif_date and cfg.use_prefix:
            self.prefix = self.get_prefix()
        else:
            self.prefix = ""

        self.interfix = cfg.interfix if cfg.interfix else ""

        self.exif_type = self.get_exif_type()
        self.type = self.exif_type.split("/")[0] if self.exif_type else "unknown"
        
        if cfg.use_subdirs:
            self.subdir = self.get_subdir()
        
        self.name_new = self.get_new_name()
        self.path_new = self.get_new_path()


def main() -> None:
    """Main function to organize media files."""
    global cfg
    
    # Initialize configuration with defaults
    cfg = init_config()
    
    # Initialize colors for terminal output
    init_colors()
    
    # Parse command line arguments and update config
    parse_args()
    
    # Freeze config to prevent accidental modifications during processing
    cfg.freeze()
    
    # Validate conditions
    check_conditions()
    
    # Print header (settings and schema)
    print_header()
    
    # Get list of files and folder info
    file_list = get_file_list(Path(cfg.source_dir))
    folder_info = get_folder_info(file_list)
    
    # Print folder information
    print_folder_info(folder_info)
    
    # Get media objects and print file information
    files = get_media_objects(file_list, folder_info)
    print_files_info(files, folder_info)
    
    # If no valid files, exit
    if folder_info['valid_files'] == 0:
        print("No valid media files to process. Exiting.")
        sys.exit(0)
    
    # Prompt user for confirmation to continue
    if not prompt_user(folder_info):
        sys.exit(0)
    
    # Process valid media files
    process_files(files, folder_info)
    
    # Print footer (summary)
    print_footer(folder_info)


# Run the main function
if __name__ == "__main__":
    main()