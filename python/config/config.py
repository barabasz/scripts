"""
Core implementation of the Config class.
"""

from typing import Any, Type, Optional, Union
from typing import get_type_hints, get_origin, get_args
from dataclasses import dataclass


@dataclass
class PropertyDescriptor:
    """Descriptor storing metadata of a single property for Config class."""
    name: str
    prop_type: Type
    default_value: Any = None
    
    def validate_type(self, value: Any) -> bool:
        """
        Checks if the value matches the type (handles Optional, Union, and generics).
        """
        prop_type = self.prop_type
        origin = get_origin(prop_type)

        # 1. Handle Union types (including Optional[T], which is Union[T, None])
        if origin is Union:
            args = get_args(prop_type)
            for arg in args:
                # Recursively check if the value matches any type in the Union
                temp_descriptor = PropertyDescriptor(self.name, arg, self.default_value)
                if temp_descriptor.validate_type(value):
                    return True
            return False  # Value doesn't match any type in the Union

        # 2. Handle None (if the type itself is not a Union)
        if value is None:
            # None is only valid if the type is explicitly type(None)
            return prop_type is type(None)

        # 3. Handle generic container types (e.g., list[str], dict[int, str])
        if origin:
            # We only check the outer container (e.g., is it a list?)
            # Validating contents (e.g., are all items strings?) is complex
            # and outside the scope of this simple validator.
            try:
                return isinstance(value, origin)
            except TypeError:
                return False  # Handle cases like isinstance(value, list[str]) which fails
        
        # 4. Handle simple types (int, str, float, list, etc.)
        try:
            return isinstance(value, prop_type)
        except TypeError:
            # This can happen if prop_type is still some unhandled
            # complex type from `typing`
            return False


class Config:
    """
    Main class for configuration management.
    
    Provides both attribute-style (config.height) and dictionary-style
    (config['height']) access with type validation.
    
    Usage example:
        config = Config(
            height=(int, 1920),
            width=(int, 1080),
            title=(Optional[str], "Default Title")
        )
        
        print(config.height)  # 1920
        config['height'] = 2560
        print(config['height'])  # 2560
        
        config.title = None   # Allowed, as type is Optional[str]
    """
    
    def __init__(self, **properties: tuple[Type, Any]):
        """
        Initializes the configuration object.
        
        Properties can be passed upon creation, e.g.:
        config = Config(
            height=(int, 1920),
            width=(int, 1080),
            title=(Optional[str], None)
        )
        """
        # Dictionary storing property descriptors
        object.__setattr__(self, '_properties', {})
        # Dictionary storing actual values
        object.__setattr__(self, '_values', {})
        
        for name, (prop_type, default_value) in properties.items():
            self.add(name, prop_type, default_value)
    
    def add(self, name: str, prop_type: Type, default_value: Any = None) -> None:
        """
        Adds a new property to the configuration.
        
        Args:
            name: Property name
            prop_type: Property type (e.g. int, str, Optional[float])
            default_value: Default value (optional)
        
        Raises:
            ValueError: If property already exists
            TypeError: If default value doesn't match the type
        """
        if name in self._properties:
            raise ValueError(f"Property '{name}' already exists")
        
        descriptor = PropertyDescriptor(name, prop_type, default_value)
        
        # Validate the default value
        if not descriptor.validate_type(default_value):
            raise TypeError(
                f"Default value {repr(default_value)} (type: {type(default_value).__name__}) "
                f"doesn't match declared type {prop_type}"
            )
        
        self._properties[name] = descriptor
        self._values[name] = default_value
    
    def remove(self, name: str) -> None:
        """
        Removes a property from the configuration.
        
        Args:
            name: Name of the property to remove
        
        Raises:
            KeyError: If property doesn't exist
        """
        if name not in self._properties:
            raise KeyError(f"Property '{name}' doesn't exist")
        
        del self._properties[name]
        del self._values[name]
    
    def update(self, **kwargs) -> None:
        """
        Updates multiple properties at once.
        
        Args:
            **kwargs: Property name-value pairs to update
        
        Raises:
            AttributeError: If property doesn't exist
            TypeError: If value doesn't match the declared type
        """
        for name, value in kwargs.items():
            setattr(self, name, value)
    
    def _format_value_for_display(self, value: Any) -> str:
        """
        Formats value for display in list() method.
        Shortens long strings and shows collection sizes.
        """
        # Handle strings - shorten if longer than 27 characters
        if isinstance(value, str):
            if len(value) > 27:
                return repr(value[:27] + '…')
            return repr(value)
        
        # Handle collections (list, tuple, dict, set) - show item count
        if isinstance(value, (list, tuple, dict, set)):
            count = len(value)
            if count == 0:
                return '<empty>'
            return f'<{count} item{"s" if count != 1 else ""}>'
        
        # For all other types (including None), use standard repr
        return repr(value)
    
    def list(self) -> None:
        """Prints all currently set properties with their values and declared types."""
        if not self._properties:
            print("No properties defined.")
            return
        
        print("Configuration properties:")
        max_name_len = max(len(name) for name in self._properties.keys())
        name_col_width = max(15, min(max_name_len + 1, 30))  # min 15, max 30
        value_col_width = 30  # Fixed width for the formatted value
        separator = " = "
        total_width = name_col_width + len(separator) + value_col_width + 1
        print("-" * (total_width + 4))

        for name in sorted(self._properties.keys()):
            descriptor = self._properties[name]
            value = self._values[name]
            prop_type = descriptor.prop_type
            origin = get_origin(prop_type)
            
            if origin is None:
                # Simple type (int, bool, str) or unparameterized generic (list, dict)
                type_name = prop_type.__name__
            else:
                # Complex typing type (Optional[str], list[str], Union[int, float])
                type_name = repr(prop_type)
                
            formatted_value = self._format_value_for_display(value)
            
            # Truncate property name if it's too long for the column
            if len(name) > (name_col_width - 1):
                display_name = name[:name_col_width - 2] + '…'
            else:
                display_name = name
            
            # Format: Name | Value | Type
            print(f"{display_name:<{name_col_width}}{separator}{formatted_value:<{value_col_width}} {type_name}")
        
        print("-" * (total_width + 4))
    
    def get_property_info(self, name: str) -> PropertyDescriptor:
        """Returns information about a property."""
        if name not in self._properties:
            raise KeyError(f"Property '{name}' doesn't exist")
        return self._properties[name]
    
    def list_properties(self) -> dict[str, PropertyDescriptor]:
        """Returns a dictionary of all properties."""
        return self._properties.copy()

    def get(self, name: str, default: Any = None) -> Any:
        """
        Gets a property value, returning a default if it doesn't exist.
        (Similar behavior to dict.get)
        """
        return self._values.get(name, default)
    
    def keys(self):
        """Returns property names (like dict.keys())"""
        return self._values.keys()

    def values(self):
        """Returns property values (like dict.values())"""
        return self._values.values()

    def items(self):
        """Returns (name, value) pairs (like dict.items())"""
        return self._values.items()

    def __contains__(self, name: str) -> bool:
        """Allows: 'property_name' in config"""
        return name in self._properties

    def __getattr__(self, name: str) -> Any:
        """Enables access to values via config.property_name"""
        if name.startswith('_'):
            # Handle private attributes like _properties, _values
            return object.__getattribute__(self, name)
        
        if name not in self._properties:
            raise AttributeError(f"Property '{name}' doesn't exist")
        
        return self._values[name]
    
    def __setattr__(self, name: str, value: Any) -> None:
        """Enables setting values via config.property_name = value"""
        if name.startswith('_'):
            # Allow setting private attributes
            object.__setattr__(self, name, value)
            return
        
        if name not in self._properties:
            raise AttributeError(
                f"Property '{name}' doesn't exist. Use add() to create it."
            )
        
        descriptor = self._properties[name]
        # Validate the new value against the stored type
        if not descriptor.validate_type(value):
            raise TypeError(
                f"Value {repr(value)} (type: {type(value).__name__}) "
                f"doesn't match declared type {descriptor.prop_type}"
            )
        
        self._values[name] = value
    
    def __len__(self) -> int:
        """Returns the number of defined properties."""
        return len(self._properties)

    def __iter__(self):
        """Allows iteration over property names (keys), like a dict."""
        return iter(self._values)

    def __getitem__(self, name: str) -> Any:
        """Enables access to values via config['property_name']"""
        if name not in self._properties:
            raise KeyError(f"Property '{name}' doesn't exist")
        try:
            return self._values[name]
        except KeyError:
             # This case should technically not be hit if _properties and _values
             # are in sync, but it's good practice.
            raise KeyError(f"Property '{name}' doesn't exist")

    def __setitem__(self, name: str, value: Any) -> None:
        """Enables setting values via config['property_name'] = value"""
        # We can just call __setattr__ since it has all the logic
        self.__setattr__(name, value)

    def __delitem__(self, name: str) -> None:
        """Enables deleting/removing properties via del config['property_name']"""
        # We can just call remove() since it has all the logic
        self.remove(name)

    def __str__(self) -> str:
        """User-friendly string representation of the object."""
        props = []
        for name in sorted(self._properties.keys()):
            descriptor = self._properties[name]
            value = self._values[name]
            # Use repr(value) for clarity (e.g., 'hello' vs hello)
            props.append(f"{name}={repr(value)} ({descriptor.prop_type})")
        
        if not props:
            return "Config(empty)"
        return f"Config({', '.join(props)})"

    def __repr__(self) -> str:
        """Canonical string representation of the object."""
        prop_count = len(self._properties)
        return f"<Config object with {prop_count} propert{'ies' if prop_count != 1 else 'y'}>"