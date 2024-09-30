# Step 1: Capture the entire lshw output into a file
lshw > lshw_output.txt

# Step 2: Add the header "==============================" to the top of the file
echo '==============================' >> lshw_output.txt

# Step 3: Replace all *- lines that are not usb, disk, medium, volume, nvme, or namespace with ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sed -i -E '/^\s*\*-(usb|disk|medium|volume|nvme|namespace)/!s/^\s*\*-.*/>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/' lshw_output.txt

# Step 4: Process the file from top to bottom, preserving only blocks with `*-`, otherwise skipping
awk '
/>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/ {
    if (block_has_star == 0) {
        skip = 1;         # Mark to skip this block if no *- was found
    } else {
        skip = 0;         # Reset the skip if *- was found
    }
    block_has_star = 0;   # Reset for the next block
    print $0;             # Always print the ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    next;
}
/\*-/ {
    block_has_star = 1;   # Mark that we found a *-
    print $0;             # Print the *- line
    skip = 0;             # Do not skip the following lines
    next;
}
!/>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/ {
    if (!skip) print;     # Print all lines until the next ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}
' lshw_output.txt > cleaned_output.txt
sed -i '/==============================/d' cleaned_output.txt
echo '==============================' >> cleaned_output.txt
# Step 6: Show the final result
rm lshw_output.txt

lshw > lshw_output.txt

# Step 2: Add the header "==============================" to the top of the file
echo '==============================' >> lshw_output.txt

# Step 3: Replace all *- lines that are not usb, disk, medium, volume, nvme, or namespace with ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sed -i -E '/^\s*\*-(usb|disk|medium|volume|nvme|namespace)/!s/^\s*\*-.*/>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/' lshw_output.txt

# Step 4: Process the file from top to bottom, preserving only blocks with `*-`, otherwise skipping
awk '
/>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/ {
    if (block_has_star == 1) {
        skip = 1;         # Mark to skip this block if no *- was found
    } else {
        skip = 0;         # Reset the skip if *- was found
    }
    block_has_star = 1;   # Reset for the next block
    print $0;             # Always print the ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    next;
}
/\*-/ {
    block_has_star = 0;   # Mark that we found a *-
    skip = 1;             # Do not skip the following lines
    next;
}
!/>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/ {
    if (!skip) print;     # Print all lines until the next ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}
' lshw_output.txt > lshw_output1.txt
rm lshw_output.txt

# Step 1: Specify the file from which you want to delete lines
target_file="cleaned_output.txt"  # Replace with the actual file you want to modify

# Step 2: Remove lines found in lshw_output1.txt from the target file
grep -vFf lshw_output1.txt "$target_file" > temp_file && mv temp_file "$target_file"

# Step 3: Remove the lshw_output1.txt file
rm lshw_output1.txt
sed -i '/==============================/d' cleaned_output.txt

# Optional: Show the modified target file
cat "$target_file"
