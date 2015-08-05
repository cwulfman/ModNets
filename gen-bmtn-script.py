#! /usr/bin/env python

import os
from string import Template
import argparse


xslfile = '/Users/cwulfman/Projects/Modnets/bmtn2rdf.xsl'
cmdTemplate = Template('saxon -s:$src -xsl:$xsl -o:$out')

def transform_files(sourcedir, targetdir):
    for root, dirs, files in os.walk(sourcedir):
        target_subdir = '/'.join((targetdir.rstrip('/'), root.lstrip('/')))
        for fname in files:
            if fname.endswith('.mets.xml'):
                source = '/'.join((root, fname))
                target = '/'.join((target_subdir, fname.replace('.mets.xml', '.rdf')))
                cmd = cmdTemplate.substitute(src=source, xsl=xslfile, out=target)
                print "echo " + cmd
                print cmd


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input_dir", help="top-level directory of source xml files.")
    parser.add_argument("-o", "--output_dir", help="target directory.")
    args = parser.parse_args()

    if args.input_dir and args.output_dir:
        transform_files(args.input_dir, args.output_dir)




