#!/bin/sh
# This script is used to merge custom resources to MicroStrategy Bundle
# Argument 1: The target bundle name.
# Argument 2: The custom bundle location.
sh "$SRCROOT/MergeBundles.sh" FinalBundle.bundle "$SRCROOT/Custom/FinalBundle.bundle"
