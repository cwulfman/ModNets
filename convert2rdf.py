#! /usr/bin/env python

import os
from string import Template

srcdir = '/Users/cwulfman/work/mjp/metsfiles/'
targetdir = '/Users/cwulfman/work/ModNets/newage/'
xslfile = '/Users/cwulfman/work/Modnets/mjp2rdf.xsl'
cmdTemplate = Template('saxon -s:$src -xsl:$xsl -o:$out')

with open('newage.txt', 'rU') as f:
    for line in f:
        source = srcdir + line.rstrip()
        target = targetdir + line.rstrip()
        cmd = cmdTemplate.substitute(src=source, xsl=xslfile, out=target)
        print "echo " + cmd
        print cmd




