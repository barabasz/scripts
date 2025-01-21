"""
function that generates UUID ver 4 (randomly generated)
following the guidelines specified in RFC 4122
https://datatracker.ietf.org/doc/html/rfc4122
"""

import random
import uuid   # for comparison


def get_uuid_v4():
    uuid_bytes = bytearray([random.randint(0, 255) for _ in range(16)])
    uuid_bytes[6] = (uuid_bytes[6] & 0x0f) | 0x40
    uuid_bytes[8] = (uuid_bytes[8] & 0x3f) | 0x80
    uuid_str = ''.join(format(byte, '02x') for byte in uuid_bytes)
    uuid4 = '-'.join([uuid_str[:8], uuid_str[8:12], uuid_str[12:16], uuid_str[16:20], uuid_str[20:]])
    return uuid4


u1 = get_uuid_v4() # using above implementation
u2 = uuid.uuid4()  # using uuid library

print(u1, u2, sep="\n")
