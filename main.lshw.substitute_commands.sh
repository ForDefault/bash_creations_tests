#!/bin/bash

# This system generates substitute commands linking blocks (e.g., $Linput_1) 
# and descriptors (e.g., product_092_1) with unique identifiers for easy querying and structure.

lshw > lshw_output.txt
input_file="lshw_output.txt"  # The file to process
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

# Read the input_file line by line
while IFS= read -r line; do
    # Check and replace UNCLAIMED without affecting quoted "UNCLAIMED"
    if [[ "$line" == *" UNCLAIMED"* && "$line" != *'"UNCLAIMED"'* ]]; then
        line=$(echo "$line" | sed 's/ UNCLAIMED/_UNCLAIMED/g')
    fi

    # Step 1: Capture the exact number of leading spaces (leading whitespaces) using length of the match
    spaces=$(echo "$line" | sed -n 's/^\( *\).*/\1/p' | awk '{ print length($0) }')

    # Check if the line starts with *- (i.e., it's a block entry)
    if [[ "$line" == *"*-"* ]]; then
        # Step 2: Remove the *- prefix and replace ":" with "_"
        clean_line="${line#*-}"
        clean_line_underscore="${clean_line//:/_}"  # Replace ":" with "_"

        # Step 3: Preserve the original form for the middle part using parentheses
        # Convert underscores inside parentheses back to spaces and wrap in double quotes
        wrapped_middle="\"$(echo ${clean_line} | tr '_' ' ')\""  # Convert _ to spaces and wrap in quotes

        # Step 4: Generate a unique identifier for the block with leading zeros
        block_id=$(printf "%03d" "$block_counter")

        # Step 5: Condensed logic for block substitute command
        substitute_command="__${clean_line_underscore}_${block_id}=${wrapped_middle}"

        # Step 6: Output the block command with the exact spacing
        printf "%*s%s\n" "$spaces" "" "$substitute_command" >> "$output_file"

        # Set the current block ID and block number for subsequent lines
        current_block_id=$block_id
        current_block_number="$block_id"

        # Increment the block counter for the next block
        block_counter=$((block_counter + 1))

        # Reset descriptor counter for new block
        descriptor_counter=1  # Start from 1 for sub-numbering within block
    else
        # If the line is not a block entry, process it as a descriptor (if a valid block is present)
        if [[ ! -z "$current_block_id" ]]; then
            # Ensure the line contains a descriptor (has a colon) before processing
            if [[ "$line" == *":"* ]]; then
                # Generate unique numbering for the descriptor within the current block
                descriptor_sub_id=$(printf "%d" "$descriptor_counter")

                # Get the descriptor name (before the colon) and value (after the colon)
                clean_descriptor=$(echo "$line" | cut -d':' -f1 | sed 's/^\s*//' | tr ' ' '_')  # Get descriptor name, replace spaces with underscores
                descriptor_value=$(echo "$line" | cut -d':' -f2- | sed 's/^\s*//')  # Get the descriptor value (after ":")

                # Handle wrapping of both descriptor and value in double quotes
                wrapped_descriptor="\"$(echo ${clean_descriptor} | tr '_' ' '):\""  # Convert underscores back to spaces for the descriptor
                wrapped_descriptor_value="\"${descriptor_value}\""  # Wrap the value in quotes

                # Build the descriptor substitute command
                descriptor_command="${clean_descriptor}_${current_block_number}_${descriptor_sub_id}=${wrapped_descriptor} output_${current_block_number}_${descriptor_sub_id}=${wrapped_descriptor_value}"

                # Output the descriptor command with the exact spacing
                printf "%*s%s\n" "$spaces" "" "$descriptor_command" >> "$output_file"

                # Increment descriptor sub-ID counter
                descriptor_counter=$((descriptor_counter + 1))
            fi
        fi
    fi

    # Step 7: Record the spacing information in spacing_data.txt (for verification or debugging)
    echo "$line spacing: $spaces" >> "$spacing_file"

done < "$input_file"

# Ensure that replacements for $L occur without changing spacing
sed -i 's/\(\s*\)\$L/\1__/g' "$output_file"

# Output the result to verify the output
cat "$output_file"

# Clean up and confirm completion
echo "Substitute commands have been generated and saved in $output_file"
echo "Spacing data has been saved in $spacing_file"



