'''
main.py
Manages all loading files. Add command line argument
for which file would like to load
'''

from load_factors import load_factors
from load_macro import load_macro
from load_prices import load_prices
import sys # for command line arguments

if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'prices':
        load_prices()
    elif cmd == 'factors':
        load_factors()
    elif cmd == 'macro':
        load_macro()
    elif cmd == 'all':
        load_prices()
        load_factors()
        load_macro()