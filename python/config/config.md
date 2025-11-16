# Config - Type-Safe Configuration Management

**Version:** 1.0.5  
**Author:** barabasz  
**License:** MIT

## 📖 Overview

`Config` is a Python class for managing configuration with:
- ✅ Dynamic property management
- ✅ Strong type validation (supports `Optional`, `Union`, generics)
- ✅ Dict-like interface
- ✅ Runtime property addition/removal

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

# Access values
print(app.debug)        # True
print(app.port)         # 8080

# Modify values
app.debug = False
app.port = 3000

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
# Direct access
value = cfg.host                        # 'localhost'

# Safe access with default
value = cfg.get('host')                 # 'localhost'
value = cfg.get('missing', 'default')   # 'default'

# Check existence
if 'host' in cfg:
    print(cfg.host)
```

---

## ✏️ Modifying Values

### Single Property
```python
cfg.port = 3000
cfg.debug = True
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
```

### Union Values
```python
cfg.port = 8080        # int
cfg.port = "auto"      # str - both OK for Union[int, str]
```

---

## ❌ Removing Properties

```python
cfg.remove('port')

# Check first
if 'port' in cfg:
    cfg.remove('port')
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

# Iteration
for key, value in cfg:
    print(f"{key}: {value}")

# Keys, values, items
print(list(cfg.keys()))     # ['debug', 'host', 'port']
print(list(cfg.values()))   # [True, 'localhost', 8080]
print(list(cfg.items()))    # [('debug', True), ...]

# Membership
if 'debug' in cfg:
    print("Debug setting exists")
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
cfg.port = "8080"    # ❌ TypeError: Value doesn't match type

cfg = Config(api=(Optional[str], None))
cfg.api = "key123"   # ✅ OK
cfg.api = None       # ✅ OK (Optional allows None)

cfg = Config(port=(Union[int, str], 8080))
cfg.port = 9000      # ✅ OK
cfg.port = "auto"    # ✅ OK
cfg.port = 3.14      # ❌ TypeError: float not in Union[int, str]
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

# Use in application
if app_config.debug:
    print(f"Running on {app_config.host}:{app_config.port}")

if app_config.database_url:
    # connect_to_database(app_config.database_url)
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

### Special Methods
- `len(cfg)` - Number of properties
- `'name' in cfg` - Check if property exists
- `for k, v in cfg` - Iterate over properties
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

4. **Check existence before access:**
   ```python
   if 'optional_setting' in cfg:
       value = cfg.optional_setting
   ```

5. **Use `.get()` for safe access:**
   ```python
   timeout = cfg.get('timeout', 30)  # Default to 30
   ```

---

## 🐛 Error Handling

```python
# TypeError: Type mismatch
try:
    cfg.port = "invalid"
except TypeError as e:
    print(f"Error: {e}")

# ValueError: Duplicate property
try:
    cfg.add('port', int, 8080)  # Already exists
except ValueError as e:
    print(f"Error: {e}")

# KeyError: Property doesn't exist
try:
    cfg.remove('nonexistent')
except KeyError as e:
    print(f"Error: {e}")

# AttributeError: Access non-existent property
try:
    value = cfg.nonexistent
except AttributeError as e:
    print(f"Error: {e}")
```

---

## 📄 License

MIT License - Copyright 2025, barabasz

## 🔗 Links

- Repository: https://github.com/barabasz/scripts/tree/main/python/config
- Version: 1.0.5