#great for getting all running vms and storage location but not to isolate usb

#!/bin/bash

# Function to extract device information (product, vendor, serial)
get_device_info() {
    device_id=$1
    source storage_devices.txt  # Source the file to get variables

    # Extract the values for product, vendor, and serial dynamically
    product_var="output_${device_id}_2"
    vendor_var="output_${device_id}_3"
    serial_var="output_${device_id}_7"

    # Retrieve the values using the variable names
    product=${!product_var}
    vendor=${!vendor_var}
    serial=${!serial_var}

    # Output the device information
    echo "product: $product"
    echo "vendor: $vendor"
    echo "serial: $serial"
}

# Function to get VM information (number, config, name, status) for active VMs
get_active_vm_info() {
    device_id=$1
    # Extract bus_info from storage_devices.txt
    bus_info_var="output_${device_id}_5"
    bus_info=$(eval echo \$$bus_info_var | tr -d '()')

    # Check if there's a match in VM configs
    vm_match=$(grep "$bus_info" /etc/pve/qemu-server/*.conf)

    if [[ -n "$vm_match" ]]; then
        for vm_conf in $(echo "$vm_match" | awk -F':' '{print $1}'); do
            vm=$(basename "$vm_conf" .conf)
            vm_status=$(qm status "$vm" | grep -q "running" && echo "Running" || echo "Stopped")
            vm_name=$(qm config "$vm" | grep -w "name" | awk '{print $2}')
            if [[ "$vm_status" == "Running" ]]; then
                echo "   VM Number: $vm"
                echo "   VM Config: $vm_conf"
                echo "   VM Name: $vm_name"
                echo "   VM Status: $vm_status"
            fi
        done
    else
        echo "No active VM found for device $device_id"
    fi
}

# Function to get VM information for inactive VMs
get_inactive_vm_info() {
    device_id=$1
    # Extract bus_info from storage_devices.txt
    bus_info_var="output_${device_id}_5"
    bus_info=$(eval echo \$$bus_info_var | tr -d '()')

    # Check if there's a match in VM configs
    vm_match=$(grep "$bus_info" /etc/pve/qemu-server/*.conf)

    if [[ -n "$vm_match" ]]; then
        for vm_conf in $(echo "$vm_match" | awk -F':' '{print $1}'); do
            vm=$(basename "$vm_conf" .conf)
            vm_status=$(qm status "$vm" | grep -q "running" && echo "Running" || echo "Stopped")
            if [[ "$vm_status" == "Stopped" ]]; then
                vm_name=$(qm config "$vm" | grep -w "name" | awk '{print $2}')
                echo "   VM Number: $vm"
                echo "   VM Config: $vm_conf"
                echo "   VM Name: $vm_name"
                echo "   VM Status: $vm_status"
            fi
        done
    else
        echo "No inactive VM found for device $device_id"
    fi
}

# Function to generate active substitute command for a device
generate_active_command() {
    device_id=$1
    echo "Mass Storage Device $device_id"
    get_device_info "$device_id"
    get_active_vm_info "$device_id"
}

# Function to generate inactive substitute command for a device
generate_inactive_command() {
    device_id=$1
    echo "Mass Storage Device $device_id"
    get_device_info "$device_id"
    get_inactive_vm_info "$device_id"
}

# Now, dynamically find all the device IDs and process them

# Step 1: Extract device IDs from storage_devices.txt
device_ids=$(grep -oP 'output_\K[0-9]+(?=_)' storage_devices.txt | sort -u)

# Step 2: Loop through each device ID and generate the commands
for device_id in $device_ids; do
    echo "Processing device ID: $device_id"
    generate_active_command "$device_id"
    generate_inactive_command "$device_id"
done
