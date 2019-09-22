#!/usr/bin/python

import sys

wmap = {}
for line in open(sys.argv[1]):
    items = line.split()
    wmap[items[0]] = items[1]

for line in open(sys.argv[2]):
    items = line.split()
    print items[0], wmap.get(items[1], items[1])
