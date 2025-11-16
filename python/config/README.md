# Config - Type-Safe Configuration Management

## 📖 Overview

`Config` is a Python class for managing configuration with:
- ✅ **Type validation at runtime** - catch errors immediately, not hours later
- ✅ **Self-documenting** - types and defaults visible in code
- ✅ **Typo protection** - `cfg.debgu = False` raises error instead of silent failure
- ✅ **Optional & Union types** - `Optional[str]`, `Union[int, str]` built-in
- ✅ **Dict-like interface** - both `cfg.key` and `cfg['key']` syntax
- ✅ **IDE autocomplete** - full IntelliSense support
- ✅ **Runtime introspection** - query types and metadata programmatically

### Why Config over dict?

```python
# ❌ Plain dict - silent failures, runtime crashes
config = {'port': 8080}
config['port'] = "invalid"  # ✓ No error now...
config['debgu'] = False     # ✓ Typo ignored...
server.listen(config['port'])  # 💥 Crashes after 1 hour!

# ✅ Config - fail fast, catch errors immediately
cfg = Config(port=(int, 8080))
cfg.port = "invalid"  # ✗ TypeError immediately!
cfg.debgu = False     # ✗ AttributeError immediately!
cfg.list()            # Shows all settings with types
```

**TL;DR:** `Config` = `dict` + type safety + self-documentation + fail fast = fewer bugs! 🚀

---

## 🚀 Quick Start

```python
from config import Config
from typing import Optional

# Create configuration
app = Config(
    debug=(bool, True),
    port=(int, 8080),
    host=(str, "localhost")
)

# Access values (two ways)
print(app.debug)        # True (attribute access)
print(app['port'])      # 8080 (dict-style access)

# Modify values (two ways)
app.debug = False       # Attribute style
app['port'] = 3000      # Dict style

# Display all properties
app.list()
```

---

## 📦 Installation

```
project/
├── config/
│   ├── __init__.py
│   └── config.py
└── your_script.py
```

```python
# your_script.py
from config import Config
```

---

## 🔧 Creating Config

### Empty Config
```python
cfg = Config()
```

### With Initial Properties (Recommended)
```python
cfg = Config(
    name=(str, "MyApp"),
    version=(str, "1.0.0"),
    debug=(bool, False),
    port=(int, 8080)
)
```

---

## ➕ Adding Properties

```python
cfg = Config()

# Basic types
cfg.add('host', str, 'localhost')
cfg.add('port', int, 8080)
cfg.add('debug', bool, False)
cfg.add('timeout', float, 30.5)

# Collections
cfg.add('tags', list, ['python', 'config'])
cfg.add('settings', dict, {'theme': 'dark'})
cfg.add('coords', tuple, (10, 20))
cfg.add('ids', set, {1, 2, 3})

# Optional (can be None)
cfg.add('api_key', Optional[str], None)

# Union (multiple allowed types)
cfg.add('port', Union[int, str], 8080)

# Generics
cfg.add('hosts', list[str], ['localhost'])
cfg.add('env', dict[str, int], {'timeout': 30})
```

---

## 📖 Reading Values

```python
# Method 1: Attribute access (recommended for static keys)
value = cfg.debug                       # True
value = cfg.host                        # 'localhost'

# Method 2: Dict-style access (useful for dynamic keys)
value = cfg['debug']                    # True
value = cfg['host']                     # 'localhost'

# Method 3: Safe access with default
value = cfg.get('host')                 # 'localhost'
value = cfg.get('missing', 'default')   # 'default'

# Check existence
if 'host' in cfg:
    print(cfg.host)

# Dynamic key access
setting = 'debug'
if setting in cfg:
    print(f"{setting} = {cfg[setting]}")
```

---

## ✏️ Modifying Values

### Single Property (Two Styles)

```python
# Attribute style (recommended for static keys)
cfg.port = 3000
cfg.debug = True

# Dict style (useful for dynamic keys)
cfg['port'] = 3000
cfg['debug'] = True

# Dynamic key modification
key = 'port'
cfg[key] = 8080
```

### Multiple Properties (Bulk Update)

```python
cfg.update(
    port=3000,
    debug=True,
    host='0.0.0.0'
)
```

### Optional Values

```python
cfg.api_key = "secret123"
cfg.api_key = None  # Allowed for Optional[str]

# Or dict-style:
cfg['api_key'] = "secret123"
cfg['api_key'] = None
```

### Union Values

```python
cfg.port = 8080        # int
cfg.port = "auto"      # str - both OK for Union[int, str]

# Or dict-style:
cfg['port'] = 8080
cfg['port'] = "auto"
```

---

## ❌ Removing Properties

```python
# Method 1: Using .remove()
cfg.remove('port')

# Method 2: Dict-style deletion
del cfg['port']

# Safe removal
if 'port' in cfg:
    del cfg['port']
```

---

## 🔍 Introspection

### Display All Properties

```python
cfg.list()
# Configuration properties:
# ------------------------------
# debug           = True         bool
# host            = 'localhost'  str
# port            = 8080         int
# ------------------------------
```

### Property Metadata

```python
info = cfg.get_property_info('port')
print(info.name)           # 'port'
print(info.prop_type)      # <class 'int'>
print(info.default_value)  # 8080
```

### All Properties

```python
props = cfg.list_properties()  # dict[str, PropertyDescriptor]
names = list(props.keys())     # ['debug', 'host', 'port']
```

---

## 🔄 Iteration & Container Operations

```python
# Length
print(len(cfg))  # 3

# Iteration over keys (like dict)
for key in cfg:
    print(key)  # 'debug', 'host', 'port'

# Iteration over keys with values
for key in cfg:
    print(f"{key} = {cfg[key]}")

# Iteration over (key, value) pairs
for key, value in cfg.items():
    print(f"{key}: {value}")

# Keys, values, items
print(list(cfg.keys()))     # ['debug', 'host', 'port']
print(list(cfg.values()))   # [True, 'localhost', 8080]
print(list(cfg.items()))    # [('debug', True), ...]

# Membership test
if 'debug' in cfg:
    print("Debug setting exists")

# Convert to dict
settings_dict = dict(cfg)   # {'debug': True, 'host': 'localhost', ...}
```

---

## 📋 String Representations

```python
# Short canonical form
repr(cfg)  # "<Config object with 3 properties>"

# Detailed user-friendly form
str(cfg)   # "Config(debug=True (bool), host='localhost' (str), ...)"

# Formatted table
cfg.list()
```

---

## ⚠️ Type Validation

Config automatically validates types:

```python
cfg = Config(port=(int, 8080))

cfg.port = 3000      # ✅ OK
cfg['port'] = 9000   # ✅ OK (dict-style also works)
cfg.port = "8080"    # ❌ TypeError: Value doesn't match type

cfg = Config(api=(Optional[str], None))
cfg.api = "key123"   # ✅ OK
cfg.api = None       # ✅ OK (Optional allows None)

cfg = Config(port=(Union[int, str], 8080))
cfg.port = 9000      # ✅ OK
cfg.port = "auto"    # ✅ OK
cfg['port'] = 3.14   # ❌ TypeError: float not in Union[int, str]
```

---

## 💡 Real-World Example

```python
from config import Config
from typing import Optional

# Application configuration
app_config = Config(
    # App info
    app_name=(str, "WebAPI"),
    version=(str, "2.0.0"),
    environment=(str, "development"),
    
    # Server
    host=(str, "localhost"),
    port=(int, 5000),
    debug=(bool, True),
    
    # Database
    database_url=(Optional[str], None),
    db_pool_size=(int, 10),
    
    # Features
    enable_api=(bool, True),
    rate_limit=(Optional[int], 100),
    allowed_origins=(list, ["http://localhost:3000"])
)

# Display configuration
app_config.list()

# Switch to production
app_config.update(
    environment="production",
    debug=False,
    host="0.0.0.0",
    port=443,
    database_url="postgresql://user:pass@db.prod.com/app"
)

# Use in application (both styles work)
if app_config.debug:
    print(f"Running on {app_config.host}:{app_config.port}")

if app_config['database_url']:
    # connect_to_database(app_config['database_url'])
    pass
```

---

## 🎯 Common Patterns

### Configuration from Environment

```python
import os

cfg = Config(
    debug=(bool, os.getenv('DEBUG', 'false').lower() == 'true'),
    port=(int, int(os.getenv('PORT', '8080'))),
    database_url=(Optional[str], os.getenv('DATABASE_URL'))
)
```

### Validation Before Use

```python
if 'database_url' in cfg and cfg.database_url:
    # Database is configured
    connect(cfg.database_url)
else:
    print("Warning: No database configured")
```

### Dynamic Configuration

```python
# Start with base config
cfg = Config(debug=(bool, False))

# Add features based on conditions
if production_mode:
    cfg.add('cache_enabled', bool, True)
    cfg.add('log_level', str, 'WARNING')
else:
    cfg.add('log_level', str, 'DEBUG')
```

### Dynamic Key Access

```python
# Process multiple settings dynamically
settings_to_check = ['debug', 'verbose', 'trace']
for setting in settings_to_check:
    if setting in cfg and cfg[setting]:
        print(f"{setting} is enabled")

# Load from dict
user_settings = {'theme': 'dark', 'lang': 'en'}
cfg = Config()
for key, value in user_settings.items():
    cfg.add(key, type(value), value)
```

---

## 📚 API Reference

### Constructor
- `Config(**properties)` - Create config with optional initial properties

### Methods
- `.add(name, type, default=None)` - Add new property
- `.remove(name)` - Remove property
- `.update(**kwargs)` - Update multiple properties
- `.get(name, default=None)` - Get value with default
- `.list()` - Display formatted table
- `.keys()` - Get property names
- `.values()` - Get property values
- `.items()` - Get (name, value) pairs
- `.get_property_info(name)` - Get PropertyDescriptor
- `.list_properties()` - Get all PropertyDescriptors

### Special Methods (Dict-like Interface)
- `cfg['name']` - Get property value (raises `KeyError` if not exists)
- `cfg['name'] = value` - Set property value
- `del cfg['name']` - Remove property
- `cfg.name` - Get property value (attribute access)
- `cfg.name = value` - Set property value (attribute access)
- `len(cfg)` - Number of properties
- `'name' in cfg` - Check if property exists
- `for key in cfg` - Iterate over property names (keys)
- `repr(cfg)` - Short representation
- `str(cfg)` - Detailed representation

### Supported Types
- **Simple:** `int`, `str`, `bool`, `float`
- **Collections:** `list`, `dict`, `tuple`, `set`
- **Optional:** `Optional[T]` (allows `None`)
- **Union:** `Union[T1, T2]` (multiple types)
- **Generics:** `list[str]`, `dict[str, int]`, etc.

---

## ⚡ Best Practices

1. **Use bulk initialization** for cleaner code:
   ```python
   # ✅ Good
   cfg = Config(debug=(bool, True), port=(int, 8080))
   
   # ❌ Verbose
   cfg = Config()
   cfg.add('debug', bool, True)
   cfg.add('port', int, 8080)
   ```

2. **Use `Optional` for nullable values:**
   ```python
   cfg = Config(api_key=(Optional[str], None))
   ```

3. **Use `.update()` for multiple changes:**
   ```python
   cfg.update(debug=False, port=3000, host='0.0.0.0')
   ```

4. **Use attribute access for static keys:**
   ```python
   # ✅ Good - clean and readable
   if cfg.debug:
       cfg.port = 8080
   ```

5. **Use dict-style access for dynamic keys:**
   ```python
   # ✅ Good - when key is in a variable
   key = 'debug'
   value = cfg[key]
   ```

6. **Check existence before access:**
   ```python
   if 'optional_setting' in cfg:
       value = cfg.optional_setting
   ```

7. **Use `.get()` for safe access:**
   ```python
   timeout = cfg.get('timeout', 30)  # Default to 30
   ```

---

## 🐛 Error Handling

```python
# TypeError: Type mismatch
try:
    cfg.port = "invalid"
    # or: cfg['port'] = "invalid"
except TypeError as e:
    print(f"Error: {e}")

# ValueError: Duplicate property
try:
    cfg.add('port', int, 8080)  # Already exists
except ValueError as e:
    print(f"Error: {e}")

# KeyError: Property doesn't exist (dict-style)
try:
    value = cfg['nonexistent']
except KeyError as e:
    print(f"Error: {e}")

# AttributeError: Property doesn't exist (attribute-style)
try:
    value = cfg.nonexistent
except AttributeError as e:
    print(f"Error: {e}")

# KeyError: Remove non-existent property
try:
    cfg.remove('nonexistent')
    # or: del cfg['nonexistent']
except KeyError as e:
    print(f"Error: {e}")
```

---

## 📄 License

MIT License - Copyright 2025, barabasz

## 🔗 Links

- Repository: https://github.com/barabasz/scripts/tree/main/python/config
- Version: 1.0.7