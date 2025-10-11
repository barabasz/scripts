#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Load file list from current directory
import os
from pathlib import Path
from typing import Dict




def get_info(info: Dict[str, int]) -> None:
    """Populate the info dictionary with some data."""
    info['files'] = 3
    info['dirs'] = 5
    info['dirs'] += 1  # Increment dirs by 1

def print_info(info: Dict[str, int]) -> None:
    """Print the information from the info dictionary."""
    print(f"Files: {info['files']}, Dirs: {info['dirs']}")

def main():
    info: Dict[str, int] = {}
    get_info(info)
    print_info(info)
    plik = Path("/Users/barabasz/GitHub/scripts/python/organize_media.py")
    print(f"File: {plik}, Size: {plik.stat().st_size} bytes")

if __name__ == "__main__":
    main()