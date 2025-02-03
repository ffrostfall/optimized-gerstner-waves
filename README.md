# Optimized Gerstner Waves

Based off (Tessendorf, J. (2001), "Simulating Ocean Water")[https://jtessen.people.clemson.edu/reports/papers_files/coursenotes2002.pdf]

## Overview

Gerstner waves are actually just a mathematical function which return the offset vector of a point, given an undisturbed point & a few other parameters.

Most Gerstner wave implementation utilize multiple waves, because that looks the best. Since we need to iterate over each wave & add all of them together, we can multithread this incredibly easily by solving each wave in a different thread.
