#!/bin/bash

help()
{
  echo "Arguments:"
  echo "-f|--folder UploadFolder (folder to upload)"
  echo "-l|--log (If signalled, also upload log files.)"
  echo "-b|--bitstream (If signalled, also upload bitstream files.)"
  echo "-d|--decode (If signalled, also upload decode results.)"
}

if [[ $# -eq 0 ]]
then
  help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--folder)
      folder="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--log)
      uploadlogfile="1"
      shift # past argument
      ;;
    -b|--bitstream)
      uploadbitstream="1"
      shift # past argument
      ;;
    -d|--decode)
      uploaddecoderesults="1"
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      help
      exit 1
      ;;
    *)
      shift # past argument
      ;;
  esac
done

echo "Collect and convert results"
if [ "$uploadbitstream" == "1" ];
then
  eval "python3 ./Qin/CollectResults.py -l -b -s $folder"
else
  eval "python3 ./Qin/CollectResults.py -l -s $folder"
fi
eval "python3 ./Qin/ConvertResultsToCSV.py ./Results/$folder ./Analysis/$folder.csv"

if [ ! -z "$ONEDRIVE_FOLDER" ];
then
  if [ "$uploadlogfile" == "1" ];
  then
    echo "Upload log files"
    eval "rclone copy ./Results/$folder onedrive-hongdong:$ONEDRIVE_FOLDER/Results/$folder"
  fi
  if [ "$uploadbitstream" == "1" ];
  then
    echo "Upload bitstreams"
    eval "rclone copy ./Bitstreams/$folder onedrive-hongdong:$ONEDRIVE_FOLDER/Bitstreams/$folder"
  fi
  echo "Upload results"
  eval "rclone copy ./Analysis/$folder.csv onedrive-hongdong:$ONEDRIVE_FOLDER/Analysis"
  if [ "$uploaddecoderesults" == "1" ];
  then
    eval "rclone copy ./Analysis/$folder-decode.csv onedrive-hongdong:$ONEDRIVE_FOLDER/Analysis"
  fi
fi
echo "Done"

