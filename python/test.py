#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from config import Config

def main():
    cnf = Config(
        name=(str, "test"),
        version=(int, 2)
    )
    cnf.name = "test_new"
    cnf.version = 5
    print(cnf.name)
    cnf.list()
    cnf.remove('name')
    cnf.

if __name__ == "__main__":
    main()