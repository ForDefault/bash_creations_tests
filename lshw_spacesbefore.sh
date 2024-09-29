#!/bin/bash

# Step 1: Capture the lshw output into a file (if needed)
lshw > lshw_output.txt

# Step 2: Find all unique space counts and their occurrences

# Extract leading spaces, sort by number of spaces, and count occurrences
awk '{ match($0, /^[ ]+/); if (RLENGTH == 0) { next }; print RLENGTH }' lshw_output.txt | sort -nr | uniq -c > leading_spaces_analysis.txt

# Step 3: Loop through each unique space count and display the total number of lines for each
echo "Spaces Report:"

while read -r count spaces; do
    # Count how many lines have the exact number of leading spaces
    space_count=$(awk -v spaces=$spaces '{ match($0, /^[ ]+/); if (RLENGTH == spaces) print }' lshw_output.txt | wc -l)
    
    # Display the results for each range of spaces
    echo "Total spaces before: $spaces spaces before"
    echo "Total amount of lines with this number: $space_count"
    echo "-------------------------------------------"
done < leading_spaces_analysis.txt
cat lshw_output.txt
# Remove temporary files if necessary
rm lshw_output.txt
