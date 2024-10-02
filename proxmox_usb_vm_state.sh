#!/bin/bash

# Output files
vm_usb_list="vm_usb_list.txt"
usb_device_info="usb_devices_storage.txt"
> "$vm_usb_list"  # Clear the file if it exists
> "$usb_device_info"  # Clear the file if it exists

# Temporary files for running and stopped VMs
running_vm_list="running_vm_list.txt"
stopped_vm_list="stopped_vm_list.txt"
> "$running_vm_list"  # Clear running VMs list
> "$stopped_vm_list"  # Clear stopped VMs list

# Step 1: Extract all Mass Storage Devices and their identifiers (###)
mass_storage_list=$(grep -B 1 "Mass storage device" substitute_commands.txt | grep "output" | awk -F'.' '{print $2}')

# Step 2: Prepare VM USB data by extracting relevant USB entries from VM .conf files
grep usb /etc/pve/qemu-server/*.conf | grep -v -e hotplug -e args > vm_usb_tmp.txt

# Step 3: Iterate through each identified Mass Storage Device
for id in $mass_storage_list; do
    # Extract bus_info for each mass storage device
    bus_info=$(grep "output.$id.5" substitute_commands.txt | sed -n 's/.*output\.'$id'\.5=\$(usb@\([0-9:]*\)).*/\1/p' | sed 's/:/-/')

    # Check if bus_info exists
    if [[ -n "$bus_info" ]]; then
        # Step 4: Compare bus_info with VM USB data and record matches
        vm_match=$(grep "$bus_info" vm_usb_tmp.txt)

        if [[ -n "$vm_match" ]]; then
            for vm_conf in $(echo "$vm_match" | awk -F':' '{print $1}'); do
                vm=$(basename "$vm_conf" .conf)
                vm_status=$(qm status "$vm" | grep -q "running" && echo "Running" || echo "Stopped")
                vm_name=$(qm config "$vm" | grep -w "name" | awk '{print $2}')

                # Extract vendor and product info from substitute_commands.txt
                vendor=$(grep "output.$id.3" substitute_commands.txt | sed -n 's/.*output\.'$id'\.3=\$(\(.*\))/\1/p')
                product=$(grep "output.$id.2" substitute_commands.txt | sed -n 's/.*output\.'$id'\.2=\$(\(.*\))/\1/p')

                # Step 5: Write running VMs to the running_vm_list and stopped to stopped_vm_list
                if [[ "$vm_status" == "Running" ]]; then
                    echo "Mass Storage Device $id" >> "$running_vm_list"
                    echo "vendor: $vendor" >> "$running_vm_list"
                    echo "product: $product" >> "$running_vm_list"
                    echo "   VM Number: $vm" >> "$running_vm_list"
                    echo "       VM Config: $vm_conf" >> "$running_vm_list"
                    echo "       VM Name: $vm_name" >> "$running_vm_list"
                    echo "       VM Status: $vm_status" >> "$running_vm_list"
                    echo "" >> "$running_vm_list"
                else
                    echo "Mass Storage Device $id" >> "$stopped_vm_list"
                    echo "product: $product" >> "$stopped_vm_list"
                    echo "vendor: $vendor" >> "$stopped_vm_list"
                    echo "    VM Number: $vm" >> "$stopped_vm_list"
                    echo "       VM Config: $vm_conf" >> "$stopped_vm_list"
                    echo "       VM Name: $vm_name" >> "$stopped_vm_list"
                    echo "       VM Status: $vm_status" >> "$stopped_vm_list"
                    echo "" >> "$stopped_vm_list"
                fi
            done
        else
            echo "No matching VM found for Mass Storage Device $id" >> "$stopped_vm_list"
        fi

        # Step 6: Extract and format USB device info into usb_devices_storage.txt
        echo "USB Device $id:" >> "$usb_device_info"
        grep -A 10 "\$usb.*\.$id" substitute_commands.txt \
        | sed 's/.*=\$(//g' | sed 's/)//g' \
        | while read -r line; do
            echo "    $line" >> "$usb_device_info"
        done
        echo "" >> "$usb_device_info"
    else
        echo "No bus_info found for Mass Storage Device $id" >> "$stopped_vm_list"
    fi
done

# Step 7: Combine the running and stopped VMs and display the result
cat "$running_vm_list" > "$vm_usb_list"
cat "$stopped_vm_list" >> "$vm_usb_list"

# Step 8: Display the generated vm_usb_list.txt and usb_devices_storage.txt
echo "========Virtual Machine USB Device========"
cat "$vm_usb_list"
echo ""
echo "========USB Device Information========"
cat "$usb_device_info"

# Cleanup
rm "$running_vm_list" "$stopped_vm_list" "vm_usb_tmp.txt"
