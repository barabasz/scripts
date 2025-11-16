# Config - Type-Safe Configuration Management

## Overview

`Config` is a Python class for managing configuration with:
- Type validation at runtime - catch errors immediately, not hours later
- Self-documenting - types and defaults visible in code
- Typo protection - `cfg.debgu = False` raises error instead of silent failure
- Optional & Union types - `Optional[str]`, `Union[int, str]` built-in
- Read-only properties - protect constants from accidental modification
- Dict-like interface - both `cfg.key` and `cfg['key']` syntax
- IDE autocomplete - full IntelliSense support
- Runtime introspection - query types and metadata programmatically

### Why Config over dict?

```python
# Plain dict - silent failures, runtime crashes
config = {'port': 8080}
config['port'] = "invalid"  # No error now...
config['debgu'] = False     # Typo ignored...
server.listen(config['port'])  # Crashes after 1 hour!

# Config - fail fast, catch errors immediately
cfg = Config(port=(int, 8080))
cfg.port = "invalid"  # TypeError immediately!
cfg.debgu = False     # AttributeError immediately!
cfg.show()            # Shows all settings with types
```

**TL;DR:** `Config` = `dict` + type safety + self-documentation + fail fast = fewer bugs!

---

## Quick Start

```python
from config import Config
from typing import Optional

# Create configuration
app = Config(
    VERSION=(str, "1.0.0", True),   # read-only
    debug=(bool, True),              # mutable
    port=(int, 8080),                # mutable
    host=(str, "localhost")          # mutable
)

# Access values (two ways)
print(app.debug)        # True (attribute access)
print(app['port'])      # 8080 (dict-style access)

# Modify mutable values (two ways)
app.debug = False       # OK
app['port'] = 3000      # OK

# Read-only properties cannot be modified
app.VERSION = "2.0.0"   # AttributeError: read-only!

# Display all properties
app.show()
# Configuration properties:
# --------------------------------------------
# VERSION          = '1.0.0'         str [RO]
# debug            = False           bool
# host             = 'localhost'     str
# port             = 3000            int
# --------------------------------------------
```

### Note

`Config` objects are NOT thread-safe. If you need to modify configuration from multiple threads, use external synchronization (e.g., threading.Lock). For read-only access from multiple threads, no lock is needed (as long as no thread modifies the config).

---

## Installation

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

## Creating Config

### Empty Config
```python
cfg = Config()
```

### With Initial Properties (Recommended)
```python
from typing import Optional

cfg = Config(
    # Read-only properties (third parameter = True)
    APP_NAME=(str, "MyApp", True),
    VERSION=(str, "1.0.0", True),
    MAX_CONNECTIONS=(int, 1000, True),
    
    # Mutable properties
    debug=(bool, False),
    port=(int, 8080),
    database_url=(Optional[str], None)
)
```

---

## Adding Properties

```python
cfg = Config()

# Basic types (mutable)
cfg.add('host', str, 'localhost')
cfg.add('port', int, 8080)
cfg.add('debug', bool, False)

# Read-only properties
cfg.add('VERSION', str, '1.0.0', readonly=True)
cfg.add('MAX_SIZE', int, 10485760, readonly=True)

# Collections
cfg.add('tags', list, ['python', 'config'])
cfg.add('settings', dict, {'theme': 'dark'})

# Optional (can be None)
from typing import Optional, Union
cfg.add('api_key', Optional[str], None)

# Union (multiple allowed types)
cfg.add('port', Union[int, str], 8080)
```

---

## Read-Only Properties

Read-only properties protect constants and configuration values that should not change during runtime.

```python
from typing import Optional
import os

cfg = Config(
    # Application constants (read-only)
    APP_NAME=(str, "MyApplication", True),
    VERSION=(str, "1.0.8", True),
    MAX_UPLOAD_SIZE=(int, 10485760, True),  # 10MB
    
    # Environment info (read-only)
    ENVIRONMENT=(str, os.getenv('ENV', 'dev'), True),
    CONFIG_DIR=(str, os.path.dirname(__file__), True),
    
    # Runtime settings (mutable)
    debug=(bool, False),
    port=(int, 8080),
    cache_enabled=(bool, True)
)

# Read-only properties can be read
print(f"{cfg.APP_NAME} v{cfg.VERSION}")  # OK

# But cannot be modified
cfg.VERSION = "2.0.0"           # AttributeError: read-only
cfg['MAX_UPLOAD_SIZE'] = 999    # AttributeError: read-only

# Mutable properties work normally
cfg.debug = True                # OK
cfg.port = 9000                 # OK

# Read-only properties CAN be removed (if needed)
del cfg['VERSION']              # OK (use with caution!)

# Check if property is read-only
info = cfg.get_property_info('APP_NAME')
if info.readonly:
    print(f"{info.name} is read-only")
```

### Use Cases for Read-Only

```python
# 1. Application metadata
cfg = Config(
    APP_VERSION=(str, "1.0.0", True),
    BUILD_DATE=(str, "2025-11-16", True)
)

# 2. Security secrets (prevent accidental change)
cfg = Config(
    API_SECRET=(str, "super-secret-key", True),
    ENCRYPTION_KEY=(str, os.getenv('ENCRYPT_KEY'), True)
)

# 3. System limits
cfg = Config(
    MAX_CONNECTIONS=(int, 1000, True),
    TIMEOUT_SECONDS=(int, 30, True)
)

# 4. Computed values (set once at startup)
cfg = Config(
    HOSTNAME=(str, os.uname().nodename, True),
    PID=(int, os.getpid(), True)
)
```

---

## Reading Values

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

## Modifying Values

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

# Read-only properties cannot be modified
cfg.VERSION = "2.0.0"  # AttributeError: Property 'VERSION' is read-only
```

### Multiple Properties (Bulk Update)

```python
cfg.update(
    port=3000,
    debug=True,
    host='0.0.0.0'
)

# Attempting to update read-only property raises error
cfg.update(VERSION="2.0.0")  # AttributeError: read-only
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

## Removing Properties

```python
# Method 1: Using .remove()
cfg.remove('port')

# Method 2: Dict-style deletion
del cfg['port']

# Read-only properties CAN be removed
del cfg['VERSION']  # Works (they can be removed, just not modified)

# Safe removal
if 'port' in cfg:
    del cfg['port']
```

---

## Introspection

### Display All Properties

```python
cfg.show()
# Configuration properties:
# --------------------------------------------
# APP_NAME         = 'MyApp'         str [RO]
# VERSION          = '1.0.0'         str [RO]
# debug            = True            bool
# host             = 'localhost'     str
# port             = 8080            int
# --------------------------------------------
```

### Property Metadata

```python
info = cfg.get_property_info('VERSION')
print(info.name)           # 'VERSION'
print(info.prop_type)      # <class 'str'>
print(info.default_value)  # '1.0.0'
print(info.readonly)       # True

# Check all read-only properties
readonly_props = [
    name for name, desc in cfg.list_properties().items()
    if desc.readonly
]
print(readonly_props)  # ['APP_NAME', 'VERSION']
```

### All Properties

```python
props = cfg.list_properties()  # dict[str, PropertyDescriptor]
names = list(props.keys())     # ['APP_NAME', 'VERSION', 'debug', ...]
```

---

## Iteration & Container Operations

```python
# Length
print(len(cfg))  # 3

# Iteration over keys (like dict)
for key in cfg:
    print(key)  # 'APP_NAME', 'VERSION', 'debug', ...

# Iteration over keys with values
for key in cfg:
    print(f"{key} = {cfg[key]}")

# Iteration over (key, value) pairs
for key, value in cfg.items():
    print(f"{key}: {value}")

# Keys, values, items
print(list(cfg.keys()))     # ['APP_NAME', 'VERSION', 'debug', ...]
print(list(cfg.values()))   # ['MyApp', '1.0.0', True, ...]
print(list(cfg.items()))    # [('APP_NAME', 'MyApp'), ...]

# Membership test
if 'debug' in cfg:
    print("Debug setting exists")

# Convert to dict
settings_dict = dict(cfg)   # {'APP_NAME': 'MyApp', ...}
```

---

## String Representations

```python
# Short canonical form
repr(cfg)  # "<Config object with 5 properties>"

# Detailed user-friendly form
str(cfg)   # "Config(APP_NAME='MyApp' (<class 'str'>), ...)"

# Formatted table (recommended)
cfg.show()
```

---

## Type Validation

Config automatically validates types:

```python
cfg = Config(port=(int, 8080))

cfg.port = 3000      # OK
cfg['port'] = 9000   # OK (dict-style also works)
cfg.port = "8080"    # TypeError: Value doesn't match type

from typing import Optional, Union

cfg = Config(api=(Optional[str], None))
cfg.api = "key123"   # OK
cfg.api = None       # OK (Optional allows None)

cfg = Config(port=(Union[int, str], 8080))
cfg.port = 9000      # OK
cfg.port = "auto"    # OK
cfg['port'] = 3.14   # TypeError: float not in Union[int, str]
```

**Note:** For generic container types like `list[str]` or `dict[int, str]`, only the container type is validated (e.g., is it a list?). Element type validation is NOT performed. Example: A `list[str]` property will accept `[123]` without error.

---

## Immutability Protection

Config objects are mutable but cannot be used as dictionary keys or in sets:

```python
cfg = Config(debug=(bool, True))

# This is prevented to avoid unexpected behavior
my_set = {cfg}              # TypeError: unhashable type: 'Config'
my_dict = {cfg: "value"}    # TypeError: unhashable type: 'Config'

# This is by design - Config objects can change, so they shouldn't be used as keys
```

---

## Real-World Example

```python
from config import Config
from typing import Optional
import os

# Application configuration with read-only constants
app_config = Config(
    # App metadata (read-only)
    APP_NAME=(str, "WebAPI", True),
    VERSION=(str, "2.0.0", True),
    ENVIRONMENT=(str, os.getenv('ENV', 'development'), True),
    MAX_UPLOAD_SIZE=(int, 10485760, True),  # 10MB
    
    # Server settings (mutable)
    host=(str, "localhost"),
    port=(int, 5000),
    debug=(bool, True),
    
    # Database (mutable)
    database_url=(Optional[str], None),
    db_pool_size=(int, 10),
    
    # Features (mutable)
    enable_api=(bool, True),
    rate_limit=(Optional[int], 100),
    allowed_origins=(list, ["http://localhost:3000"])
)

# Display configuration
app_config.show()

# Switch to production (only mutable properties)
app_config.update(
    debug=False,
    host="0.0.0.0",
    port=443,
    database_url="postgresql://user:pass@db.prod.com/app"
)

# Constants remain protected
print(f"Running {app_config.APP_NAME} v{app_config.VERSION}")
print(f"Environment: {app_config.ENVIRONMENT}")

# Use in application
if app_config.debug:
    print(f"Debug: Running on {app_config.host}:{app_config.port}")

if app_config['database_url']:
    # connect_to_database(app_config['database_url'])
    pass
```

---

## Common Patterns

### Configuration from Environment

```python
import os

cfg = Config(
    # Read-only from environment
    ENVIRONMENT=(str, os.getenv('ENV', 'dev'), True),
    SECRET_KEY=(str, os.getenv('SECRET_KEY'), True),
    
    # Mutable settings
    debug=(bool, os.getenv('DEBUG', 'false').lower() == 'true'),
    port=(int, int(os.getenv('PORT', '8080'))),
    database_url=(Optional[str], os.getenv('DATABASE_URL'))
)
```

### Application Constants

```python
cfg = Config(
    # Version info (read-only)
    VERSION=(str, "1.0.8", True),
    BUILD_DATE=(str, "2025-11-16", True),
    
    # Limits (read-only)
    MAX_CONNECTIONS=(int, 1000, True),
    RATE_LIMIT=(int, 100, True),
    
    # Runtime settings (mutable)
    current_connections=(int, 0),
    requests_count=(int, 0)
)

# Counters can change
cfg.current_connections += 1
cfg.requests_count += 1

# But limits cannot
# cfg.MAX_CONNECTIONS = 2000  # Error!
```

### Validation Before Use

```python
if 'database_url' in cfg and cfg.database_url:
    connect(cfg.database_url)
else:
    print("Warning: No database configured")

# Check read-only status
info = cfg.get_property_info('VERSION')
if info.readonly:
    print(f"{info.name} is a constant: {cfg.VERSION}")
```

### Dynamic Key Access

```python
# Process multiple settings dynamically
settings_to_check = ['debug', 'verbose', 'trace']
for setting in settings_to_check:
    if setting in cfg and cfg[setting]:
        print(f"{setting} is enabled")

# Identify all constants
constants = {
    name: cfg[name]
    for name in cfg.keys()
    if cfg.get_property_info(name).readonly
}
print(f"Constants: {constants}")
```

---

## API Reference

### Constructor
- `Config(**properties)` - Create config with optional initial properties
  - Format: `name=(type, value)` for mutable properties
  - Format: `name=(type, value, True)` for read-only properties

### Methods
- `.add(name, type, default=None, readonly=False)` - Add new property
- `.remove(name)` - Remove property (works for both mutable and read-only)
- `.update(**kwargs)` - Update multiple properties (read-only will raise error)
- `.get(name, default=None)` - Get value with default
- `.show()` - Display formatted table (shows [RO] for read-only)
- `.keys()` - Get property names
- `.values()` - Get property values
- `.items()` - Get (name, value) pairs
- `.get_property_info(name)` - Get PropertyDescriptor (includes `readonly` field)
- `.list_properties()` - Get all PropertyDescriptors

### Special Methods (Dict-like Interface)
- `cfg['name']` - Get property value (raises `KeyError` if not exists)
- `cfg['name'] = value` - Set property value (raises `AttributeError` if read-only)
- `del cfg['name']` - Remove property
- `cfg.name` - Get property value (attribute access)
- `cfg.name = value` - Set property value (raises `AttributeError` if read-only)
- `len(cfg)` - Number of properties
- `'name' in cfg` - Check if property exists
- `for key in cfg` - Iterate over property names (keys)
- `repr(cfg)` - Short representation
- `str(cfg)` - Detailed representation
- `hash(cfg)` - Raises `TypeError` (Config objects are unhashable)

### Supported Types
- **Simple:** `int`, `str`, `bool`, `float`
- **Collections:** `list`, `dict`, `tuple`, `set`
- **Optional:** `Optional[T]` (allows `None`)
- **Union:** `Union[T1, T2]` (multiple types)
- **Generics:** `list[str]`, `dict[str, int]`, etc. (container validation only)

---

## Best Practices

1. **Use read-only for constants:**
   ```python
   # Good - constants are protected
   cfg = Config(
       VERSION=(str, "1.0.0", True),
       MAX_SIZE=(int, 1000, True),
       debug=(bool, False)
   )
   ```

2. **Use bulk initialization** for cleaner code:
   ```python
   # Good
   cfg = Config(
       VERSION=(str, "1.0.0", True),
       debug=(bool, True),
       port=(int, 8080)
   )
   
   # Verbose
   cfg = Config()
   cfg.add('VERSION', str, '1.0.0', readonly=True)
   cfg.add('debug', bool, True)
   cfg.add('port', int, 8080)
   ```

3. **Use `Optional` for nullable values:**
   ```python
   from typing import Optional
   cfg = Config(api_key=(Optional[str], None))
   ```

4. **Use `.update()` for multiple changes:**
   ```python
   cfg.update(debug=False, port=3000, host='0.0.0.0')
   ```

5. **Use attribute access for static keys:**
   ```python
   # Good - clean and readable
   if cfg.debug:
       cfg.port = 8080
   ```

6. **Use dict-style access for dynamic keys:**
   ```python
   # Good - when key is in a variable
   key = 'debug'
   value = cfg[key]
   ```

7. **Check read-only status before attempting modification:**
   ```python
   info = cfg.get_property_info('VERSION')
   if not info.readonly:
       cfg.VERSION = "2.0.0"
   ```

8. **Use `.get()` for safe access:**
   ```python
   timeout = cfg.get('timeout', 30)  # Default to 30
   ```

---

## Error Handling

```python
from typing import Optional

# TypeError: Type mismatch
try:
    cfg.port = "invalid"
except TypeError as e:
    print(f"Error: {e}")

# AttributeError: Read-only property
try:
    cfg.VERSION = "2.0.0"  # VERSION is read-only
except AttributeError as e:
    print(f"Error: {e}")  # "Property 'VERSION' is read-only"

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

# TypeError: Unhashable (cannot use in set/dict keys)
try:
    my_set = {cfg}
except TypeError as e:
    print(f"Error: {e}")  # "unhashable type: 'Config'"
```

---

## License

MIT License - Copyright 2025, barabasz

## Links

- Repository: https://github.com/barabasz/scripts/tree/main/python/config
- Version: 1.1.0
- Author: barabasz
- Date: 2025-11-17