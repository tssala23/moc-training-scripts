#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: ${1} <enable|disable>"
fi

if [[ "$OPERATION" == "enable" ]]; then

  for BDF in `lspci -d "*:*:*" | awk '{print $1}'`; do
	setpci -v -s ${BDF} ECAP_ACS+0x6.w > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		continue
	fi
	setpci -v -s ${BDF} ECAP_ACS+0x6.w=0000
	setpci -v -s ${BDF} ECAP_ACS+0x6.w
  done

elif [[ "$OPERATION" == "disable" ]]; then

  for BDF in `lspci -d "*:*:*" | awk '{print $1}'`; do
        setpci -v -s ${BDF} ECAP_ACS+0x6.w > /dev/null 2>&1
        if [ $? -ne 0 ]; then
                continue
        fi
        setpci -v -s ${BDF} ECAP_ACS+0x6.w=001d
        setpci -v -s ${BDF} ECAP_ACS+0x6.w
  done

else
  echo "Unknown option ${OPERATION}"
  exit 1
fi
