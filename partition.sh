#!/bin/bash

# Got from https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $1
  d # Delete first partition
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
    # default - end of disk
  a # make a partition bootable
    # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF
