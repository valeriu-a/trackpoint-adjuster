#!/usr/bin/env bash

# Check if we're running this with sudo/as root
if [[ $(id -u) -gt 0 ]]; then
  echo "You need to run this using sudo or as the root user."
  exit 1
fi

help() {
  echo -e "\nThis program can be used to set the sensitivity, speed and
to turn on the Press to Select option which allows you
to tap to right click on  your Thinkpad trackpoint.

You have to run this using sudo or as the root user.

Options:
-t,
  Enables or disables Press to Select. Takes 1 or 0. Default is 0.
-s,
  Sets the sensitivity of the trackpoint. Takes values from 0 to 255.
-f,
  Sets the speed of the trackpoint. Takes values from 0 to 255.

Usage: sudo $basename $0 [ -t 1 or 0 ] [ -s 0 to 255 ] [ -f 0 to 255 ]"
}

usage() {
  echo -e "Cannot change settings to that value. Use -h for help.
Usage: $basename $0 [ -t 1 or 0 ] [ -s 0 to 255 ] [ -f 0 to 255 ]" 1>&2
}

# Most Thinkpads now have a trackpoint and a touchbar,
# the prior being located in the below directory.
sys_dir="/sys/devices/platform/i8042/serio1/serio2"

# If the device does not have a touchbar, strip the last part of the dir.
if [[ ! -d ${sys_dir} ]]; then
  sys_dir=$(echo ${sys_dir} | rev | cut -d '/' -f2- | rev)
fi

select_file="${sys_dir}/press_to_select"
sensitivity_file="${sys_dir}/sensitivity"
speed_file="${sys_dir}/speed"

limit_check() {
  regx='^[0-9]+$'
  if [[ $1 -gt $2 && $1 =~ $regx ]]; then
    usage
    exit 1
  fi
}

while getopts ":t:s:f:h" opts; do
  case "${opts}" in
    h)
      help
      exit 0
    ;;
    t)
      limit_check "${OPTARG}" 1
      select=${OPTARG}
      ;;
    s)
      limit_check "${OPTARG} "255
      sensitivity=${OPTARG}
      ;;
    f)
      limit_check "${OPTARG}" 255
      speed=${OPTARG}
      ;;
    \?)
      help
      exit 1
    ;;
    *)
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [[ -z ${select// } ]]; then
  select=$(cat "${select_file}")
  echo "Value for Press to Select was not provided. Will leave the existing one: ${select}."
else
  echo "Setting Press to Select for the touchpoint to ${select}."
  echo -n $select > "${select_file}"
fi

if [[ -z ${sensitivity// } ]]; then
  sensitivity=$(cat "${sensitivity_file}")
  echo "Value for touchpoint sensitivity was not provided. Will leave the existing one: ${sensitivity}."
else
  echo "Setting touchpoint sensitivity to ${sensitivity}."
  echo -n $sensitivity > "${sensitivity_file}"
fi

if [[ -z ${speed} ]]; then
  speed=$(cat "${speed_file}")
  echo "Value for touchpoint speed was not provided. Will leave the existing one: ${speed}."
else
  echo "Setting touchpoint speed to ${speed}."
  echo -n $speed > "${speed_file}"
fi
