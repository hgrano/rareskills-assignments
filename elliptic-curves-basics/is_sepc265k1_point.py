p = 2 ** 256 - 2 ** 32 - 977

def is_sepc265k1_point(x, y):
  return y ** 2 == (x ** 3 + 7) % p
