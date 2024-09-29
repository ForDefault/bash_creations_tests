#!/bin/bash

# Step 1: Capture the entire lshw output into a file
lshw > lshw_output.txt

# Step 2: Add the header "==============================" to the top of the file
sed -i '1i==============================' lshw_output.txt

# Step 3: Verify which sections would be kept using grep (including namespace now)
grep -E '^\s*\*-(usb|disk|medium|volume|nvme|namespace)' lshw_output.txt

# Step 4: Replace all `*-` lines that are not usb, disk, medium, volume, nvme, or namespace with ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sed -i -E '/^\s*\*-(usb|disk|medium|volume|nvme|namespace)/!s/^\s*\*-.*/>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/' lshw_output.txt

# Step 5: Process the file for selective erasure, keeping the "=============================="
awk '
/==============================/ { 
    if (block_has_star == 0) {
        skip = 1;         # Mark to skip this block if no *- was found
    } else {
        skip = 0;         # Reset the skip if *- was found
    }
    block_has_star = 0;   # Reset for the next block
    print $0;             # Always print the "=============================="
    next;
}
/\*-/ {
    block_has_star = 1;   # Mark that we found a *-
    print $0;             # Print the *- line
    next;
}
{ if (!skip) print; }     # Print all other lines unless skipping
' lshw_output.txt > cleaned_output.txt

# Step 6: Remove all "==============================" and empty lines
sed -i '/==============================/d' cleaned_output.txt
sed -i '/^$/d' cleaned_output.txt

# Step 7: Show the final result
cat cleaned_output.txt

# Step 8: Remove the original lshw output file
rm lshw_output.txt
