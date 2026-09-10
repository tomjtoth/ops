#!/bin/bash

# don't launch this script, maaan!
return 0

title="The Great Gatsby"
for layout in 1:3 2:3 3:3 4:3 5:3 6:3 7:5 8:3 9:3; do
    part=${layout%:*}
    max=${layout#*:}
    
    while [ $max -gt 0 ]; do
        current=$((max--))
        file="$title - Ch$part-$current.mp3"

        curl -L -o "$file" https://esl-bits.eu/ESL.English.Learning.Audiobooks/Great.Gatsby/Ch$part/$current/audio.mp3 &
    done
done


max=11
title="The Time Keeper"
while [ $max -gt 0 ]; do
    current=$(printf '%02d' "$max")
    file="$title - $current.mp3"

    curl -o "$file" https://esl-bits.eu/ESL.English.Learning.Audiobooks/TimeKeeper/$current/z.mp3 &
    
    ((max--))
done


title="Doctor Dolittle"
for current in  1-3 4-6 	  7-9 10-12 13-15 16-18 19-21
do
    file="$title - ${current//// - }.mp3"

    curl -o "$file" https://esl-bits.eu/Novellas.for.ESL.Students/Doolittle/$current/z.mp3 &
done



