#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pyconf import Config

from typing import Optional, Union

# Test 1: Union z None
cfg = Config()

cfg.add('name', str, "", True)
# cfg.freeze()
cfg.show()

cfg.name = 'TestName'
