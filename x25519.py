def x25519_public_key(private_key: int, clamped: bool = False) -> int:
    x0 = 9
    y0 = 14781619447589544791020593568409986887264606134616475288964881837755586237401
    n = x25519_clamp(private_key) if clamped else private_key
    isinf, x, _y = x25519_scalarmult(x=x0, y=y0, n=n)
    assert not isinf
    return x


def x25519_clamp(n: int) -> int:
    n = bytearray(n.to_bytes(32, byteorder='little'))
    n[0] &= 248
    n[31] &= 127
    n[31] |= 64
    return int.from_bytes(bytes(n), byteorder='little')


def x25519_scalarmult(x: int, y: int, n: int) -> tuple[bool, int, int]:
    pinf, px, py = False, x, y
    qinf, qx, qy = True, 0, 0
    while n != 0:
        if n & 1: qinf, qx, qy = x25519_add(qinf, qx, qy, pinf, px, py)
        pinf, px, py = x25519_add(pinf, px, py, pinf, px, py)
        n >>= 1
    return qinf, qx, qy


def x25519_add(
    pinf: bool, px: int, py: int,
    qinf: bool, qx: int, qy: int
) -> tuple[bool, int, int]:
    if pinf: return qinf, qx, qy
    if qinf: return pinf, px, py
    if px == qx and py != qy: return True, 0, 0
    p = 2**255 - 19
    N = (qy - py) if px != qx else (3*px**2 + 973324*px + 1)
    D = (qx - px) if px != qx else (2*py)
    L = N * modular_inv(D, p)
    x = L**2 - 486662 - px - qx
    y = - L*(x - px) - py
    return False, x%p, y%p


def modular_inv(a: int, p: int) -> int:
    u0, u1 = 1, 0
    v0, v1 = 0, 1
    while p:
        q, r = divmod(a, p)
        u1, u0 = u0 - q*u1, u1
        v1, v0 = v0 - q*v1, v1
        a, p = p, r
    assert a == 1
    return u0
