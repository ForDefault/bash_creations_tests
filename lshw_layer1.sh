#!/bin/bash

lshw > lshw_output.txt

sed -i '1i==============================' lshw_output.txt


sed -i -E '/\*-usb|\*-disk|\*-medium|\*-volume|\*-nvme/!s/\*-.*/==============================' lshw_output.txt

awk '
/==============================/ { 
    if (block_has_star == 0) {
        skip = 1;  
    } else {
        skip = 0;  
    }
    block_has_star = 0;  
    print $0;            
    next;
}
/\*-/ {
    block_has_star = 1;  
    print $0;            
    next;
}
{ if (!skip) print; }    
' lshw_output.txt > cleaned_output.txt

cat cleaned_output.txt
rm lshw_output.txt
