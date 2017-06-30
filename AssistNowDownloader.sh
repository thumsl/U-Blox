#!/bin/bash

# Saves downloaded data to $2
function getOnlineData() {
  sv1="https://${1}-live1.services.u-blox.com/GetOnlineData.ashx?token=${token};gnss=${gnss};datatype=${datatype};format=$format;";
  sv2="https://${1}-live2.services.u-blox.com/GetOnlineData.ashx?token=${token};gnss=${gnss};datatype=${datatype};format=$format;";

  if ( curl "$sv1" -o "$2" 2> /dev/null ); then
    header=$(dd if="$2" ibs=2 count=1 2> /dev/null | xxd -ps);
      echo "$header";
    if [ "$header" == "b562" ]; then
      echo "File \"$2\" downloaded successfully from server1 (live1.services.u-blox.com)."
      return 0;
    fi
  elif ( curl "$sv2" -o "$2" 2> /dev/null ); then
    header=$(dd if="$2" ibs=2 count=1 2> /dev/null | xxd -ps);
    if [ "$header" == "b562" ]; then
      echo "File \"$2\" downloaded successfully from server2 (live1.services.u-blox.com)."
      return 0;
    fi
  else
    echo "Download failed, please check your internet connection and try again.";
    return 1;
  fi
}

function checkAndDownload() {
  if ! [[ -f "$2" ]]; then
    echo "File doesnt exist";
    getOnlineData $1 $2;
    return 1;
  elif [[ $(date +%s -r "$2") -gt $(date +%s --date="2 hours ago") ]]; then
    echo "File exists and is less than 2 hours old, use -f to force the download anyway";
    return 1;
  else
    getOnlineData $1 $2;
  fi
  
  return 0;
}

token="IzTVkQZ8EUyTEfHy5qPGuQ";
gnss="gps,glo";
datatype="eph,alm,aux";
format="mga";
FORCE=false;

while getopts t:f opt
do	case "$opt" in
	t) TYPE="$OPTARG";;
	f)	FORCE=true;;
	[?])
    printf "Usage: $0\n\t-f: Force re-download\n\t-t [online|offline]: set type\n";
		exit 1;;
	esac
done

if [[ "$TYPE" != "online" && "$TYPE" != "offline" ]]; then
  echo "Type must be either \"online\" or \"offline\", closing.";
  exit 1;
else
  FILE="AssistNow_$TYPE.bin";
  echo "$FORCE"

  if [ "$FORCE" == true ]; then
    getOnlineData $TYPE $FILE;
    exit $?;
  else
    checkAndDownload $TYPE $FILE;
    exit $?;
  fi
fi
