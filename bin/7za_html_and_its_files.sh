#!/bin/bash

for filename in ./*.html; do
    7za a -r -- "${filename%%.html}.7z" "$filename" "${filename%%.html}_files"
done
