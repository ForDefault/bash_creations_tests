#!/bin/bash

# This system generates substitute commands linking blocks (e.g., $Linput.1) 
# and descriptors (e.g., product.092.1) with unique identifiers for easy querying and structure.
# $Linput.1=$(input:1)=$input.1.092 identifies a block called input:1, assigning it a unique ID 
# of .092.
# Inside this block, descriptors like product and physical_id are numbered sequentially (e.g., 
# .092.1, .092.2).
# The descriptors (e.g., product.092.1) are linked to their values, 
# like output.092.1=$(Power Button) for easy querying.


lshw > lshw_output.txt
input_file="lshw_output.txt"  # Change to the actual file you're using
output_file="substitute_commands.txt"
spacing_file="spacing_data.txt"

# Clear the output files before starting
> "$output_file"
> "$spacing_file"

# Initialize counters for unique numbering
block_counter=0
descriptor_counter=0
current_block_id=""
current_block_number=""

# Read the cleaned_output.txt file line by line
while IFS= read -r line; do
    # Step 1: Capture the exact number of leading spaces (leading whitespaces)
    spaces=$(echo "$line" | sed -n 's/^\( *\).*/\1/p' | wc -c)

    # Check if the line starts with *- (i.e., it's a block entry)
    if [[ "$line" == *"*-"* ]]; then
        # Step 2: Remove the *- prefix and replace ":" with "."
        clean_line="${line#*-}"
        clean_line_dot="${clean_line//:/\.}"  # For first and third parts

        # Step 3: Preserve the original form for the middle part using parentheses
        original_middle="\$(${clean_line})"

        # Step 4: Generate a unique identifier for the block with leading zeros
        block_id=$(printf "%03d" "$block_counter")

        # Step 5: Build the 3-part block substitute command using the original form for the middle
        substitute_command="\$L${clean_line_dot}=${original_middle}=\$${clean_line_dot}.${block_id}"

        # Step 6: Output the block command with exact spacing
        printf "%*s%s\n" "$spaces" "" "$substitute_command" >> "$output_file"

        # Set the current block ID and block number for subsequent lines
        current_block_id=$block_id
        current_block_number="$block_id"

        # Increment the block counter for the next block
        block_counter=$((block_counter + 1))

        # Reset descriptor counter for new block
        descriptor_counter=1  # Start from 1 for sub-numbering within block
    else
        # If the line is not a block entry, it's a descriptor line (e.g., description, product)
        if [[ ! -z "$current_block_id" ]]; then
            # Generate unique numbering for the descriptor within the current block
            descriptor_sub_id=$(printf "%d" "$descriptor_counter")

            # Replace spaces in the descriptor name with underscores
            clean_descriptor=$(echo "$line" | cut -d':' -f1 | sed 's/^\s*//' | tr ' ' '_')  # Get descriptor name, replace spaces with underscores
            descriptor_value=$(echo "$line" | cut -d':' -f2- | sed 's/^\s*//')  # Get the descriptor value (after ":")

            # Build the descriptor substitute command: link to block number and descriptor sub-ID
            descriptor_command="${clean_descriptor}.${current_block_number}.${descriptor_sub_id}=\$(${clean_descriptor}:)output.${current_block_number}.${descriptor_sub_id}=\$(${descriptor_value})"

            # Output the descriptor command with exact spacing
            printf "%*s%s\n" "$spaces" "" "$descriptor_command" >> "$output_file"

            # Increment descriptor sub-ID counter
            descriptor_counter=$((descriptor_counter + 1))
        fi
    fi

    # Step 7: Record the spacing information in spacing_data.txt (for verification or debugging)
    echo "$line spacing: $spaces" >> "$spacing_file"

done < "$input_file"

# Output the result to verify the output
cat "$output_file"

# Clean up and confirm completion
echo "Substitute commands have been generated and saved in $output_file."
echo "Spacing data has been saved in $spacing_file."


# Clean up and confirm completion
echo "Substitute commands have been generated and saved in $output_file."
echo "Spacing data has been saved in $spacing_file."
