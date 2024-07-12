from ecpy.curves import Curve
from sha3 import keccak_256
from random import SystemRandom

cv = Curve.get_curve('secp256k1')

cryptogen = SystemRandom()
private_key_limit = 2 ** 256

while True:
  private_key = cryptogen.randrange(private_key_limit)

  pu_key = private_key * cv.generator # just multiplying the private key by generator point (EC multiplication)

  concat_x_y = pu_key.x.to_bytes(32, byteorder='big') + pu_key.y.to_bytes(32, byteorder='big')
  eth_addr = keccak_256(concat_x_y).digest()[-20:].hex()

  if eth_addr.startswith('0000'):
    print('private key: ', hex(private_key))
    print('eth_address: ', '0x' + eth_addr)
    break;
