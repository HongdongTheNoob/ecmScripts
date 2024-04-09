# Before running tests:
# Copy executable files into $home_folder/Preprocessing/App_{$BuildLabels}

#!/bin/bash
help()
{
  echo "Arguments:"
  echo "-s|--sort SortListFile"
  echo "-o|--output {OutputFolders[i]} (default: $home_folder/outputs/example)"
  echo "-d|--dataset DatasetFolder (default: /data/jvet-ctc)"
  echo "-f|--frame_count FrameCount (run whole sequences if absent)" 
  echo "-b|--build_label multiple BuildLabels, separately by comma"
  echo "-k|--skip_reconstruct (if signalled, reconstructed yuv files will not be produced)"
  echo "1) {OutputFolders[i]} will be set as $home_folder/outputs/BuildLabels;"
  echo "2) TestAppFolders will be set as \$pwd/App_BuildLabel;"
}

if [ $# -eq 0 ]
then
  help
  exit 1
fi

BuildLabels=()
IFS=','

while [ $# -gt 0 ]; do
  case $1 in
    -s|--sort)
      txt="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--output)
      Testfields="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--dataset)
      dataset="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--frame_count)
      FrameCount="$2"
      shift # past argument
      shift # past value
      ;;
    -b|--build_label)
      read -a BuildLabels <<< "$2"
      shift # past argument
      shift # past value
      ;;
    -k|--skip_reconstruct)
      SkipReconstruct=1
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

cores=$(nproc)
process_limit=$((cores / 2))

originaldirectory=$(pwd)
home_folder="/data/hongdong.qin"
cfgdirectory="$home_folder/ecm/cfg"

# set default paths and convert relative paths to absolute paths
if [ -z "$BuildLabels" ]
then
  exit 1
fi

buildCount=${#BuildLabels[@]}
for ((i = 0; i < $buildCount; i++)); do
  echo "${BuildLabels[i]}"
done

Testfields=()
TestAppFolders=()
for ((i = 0; i < $buildCount; i++)); do
  Testfields+=( "$home_folder/outputs/${BuildLabels[i]}" )
  TestAppFolders+=( "$originaldirectory/App_${BuildLabels[i]}" )
done

if [ -z "$dataset" ]
then
  dataset="/data/jvet-ctc"
elif [ "${dataset:0:1}" != "/" ]
then
  dataset="$originaldirectory/$dataset"
fi

echo "Process $txt line by line." 
#echo "$Testfields"
#echo "$dataset"
while IFS= read -r line
do
  # echo $line
  encfg=$(echo $line | cut -d " " -f 1) # RA
  # col2=$(echo $line | cut -d " " -f 2) # Class
  ClassName=$(echo $line | cut -d " " -f 3) # A1
  Class=$(echo "Class$ClassName")
  name=$(echo $line | cut -d " " -f 4) # Campfire
  QP1=$(echo $line | cut -d " " -f 5) # 22
  QP="${QP1:0:2}"
  ReadStartFrame=$(echo $line | cut -d " " -f 6)
  ReadFrameCount=$(echo $line | cut -d " " -f 7)
    
  # echo "$encfg $ClassName $Class $name $QP1 $QP"

  if [[ "$encfg" != "RA" ]] && [[ "$encfg" != "LP" ]] && [[ "$encfg" != "LB" ]] && [[ "$encfg" != "AI" ]]
  then
      echo "continue"
      continue
  fi

  echo "=== a new processing core ==="
	echo "$encfg $Class $name $QP"

  OutputFolders=()
  for ((i = 0; i < $buildCount; i++)); do
    OutputFolders+=( "$Testfields/$Class/$name" )
    $(mkdir -p "$Testfields/$Class/$name")
  done

  cd $originaldirectory

  configfilelist=()
  # encoding configuration
  encodecfg=""
  if [ "$encfg" == "RA" ]; then
  encodecfg="$cfgdirectory/encoder_randomaccess_ecm.cfg"  #  encoder_cfg
  elif [ "$encfg" == "LP" ]; then
  encodecfg="$cfgdirectory/encoder_lowdelay_P_ecm.cfg"
  elif [ "$encfg" == "LB" ]; then
  encodecfg="$cfgdirectory/encoder_lowdelay_ecm.cfg"
  elif [ "$encfg" == "AI" ]; then
  encodecfg="$cfgdirectory/encoder_intra_ecm.cfg"
  fi
  configfilelist+=("$encodecfg")

  # configurations per-class
  # JVET-AF2017 Section 6
  classcfg=""
  if [ "$encfg" == "RA" ]
  then
    case $ClassName in
    "A1"|"A2") classcfg="$cfgdirectory/per-class/classA_randomaccess.cfg"
    ;;
    "B"|"C"|"D") classcfg="$cfgdirectory/per-class/class${ClassName}_randomaccess.cfg"
    ;;
    "F"|"TGM") classcfg="$cfgdirectory/per-class/classF.cfg"
    ;;
    "H1") classcfg="$cfgdirectory/per-class/classB_randomaccess.cfg $cfgdirectory/per-class/classH1.cfg"
    ;;
    "H2") classcfg="$cfgdirectory/per-class/classA_randomaccess.cfg $cfgdirectory/per-class/classH2.cfg"
    ;;
    esac
  elif [ "$encfg" == "AI" ]
  then
    case $ClassName in
    "A1"|"A2") classcfg="$cfgdirectory/per-class/classA.cfg"
    ;;
    "F"|"TGM") classcfg="$cfgdirectory/per-class/classF.cfg"
    ;;
    "H1") classcfg="$cfgdirectory/per-class/classH1.cfg"
    ;;
    "H2") classcfg="$cfgdirectory/per-class/classA.cfg $cfgdirectory/per-class/classH2.cfg"
    ;;
    esac
  else # LB/LP
    case $ClassName in
    "B") classcfg="$cfgdirectory/per-class/classB_lowdelay.cfg"
    ;;
    "F"|"TGM") classcfg="$cfgdirectory/per-class/classF.cfg"
    ;;
    "H1") classcfg="$cfgdirectory/per-class/classH1.cfg"
    ;;
    "H2") classcfg="$cfgdirectory/per-class/classA.cfg $cfgdirectory/per-class/classH2.cfg"
    ;;
    esac
  fi
  if [ -n "$classcfg" ]; then
    configfilelist+=("$classcfg")
  fi
  
  # TODO
  # need to add specific config file into configfilelist ($cfgdirectory/per-sequence); find the corresponding configfile according to "name"
  # sequencecfg=$(echo $name | cut -d "_" -f 1) # Campfire
  # case $ClassName in
  #     "A1"|"A2"|"B"|"C"|"D"|"F"|"TGM") sequencecfg=$(find $cfgdirectory/per-sequence/ -type f -name "$sequencecfg*")
  #     ;;
  #     "H1") sequencecfg=$(find $cfgdirectory/per-sequence-HDR/ -type f -name "H1_$sequencecfg*")
  #     ;;
  #     "H2") sequencecfg=$(find $cfgdirectory/per-sequence-HDR/ -type f -name "H2_$sequencecfg*")
  #     ;;
  # esac
  # sequencecfg=$(echo $name | cut -d "_" -f 1) # Campfire
  case $ClassName in
    "A1"|"A2"|"B"|"C"|"D"|"E"|"F"|"TGM") sequencecfg="$cfgdirectory/per-sequence/$name.cfg"
    ;;
    "H1") sequencecfg="$cfgdirectory/per-sequence-HDR/$name.cfg"
    ;;
    "H2") sequencecfg="$cfgdirectory/per-sequence-HDR/$name.cfg"
    ;;
  esac

  # echo $sequencecfg
  if [ -z "$sequencecfg" ]
  then
    echo "can not find sequencecfg"
    continue
  fi
  # configfilelist="$configfilelist $classcfg $sequencecfg"
  configfilelist+=("$sequencecfg")
  
  # add configuration files (absolute path) to command
  # configfilearray=($configfilelist)
  configsincommand=""
  for i in "${configfilelist[@]}"; do
    configsincommand="$configsincommand -c $i"
  done

  # other files
  outputreconstructs=()
  outputlogfiles=()
  outputbitstreams=()
  for ((i = 0; i < $buildCount; i++)); do
    if [ -z "$ReadStartFrame" ]
    then
      if [ -z "$SkipReconstruct" ]
      then
        outputreconstructs+=( "${OutputFolders[i]}/rec-$name-$encfg-$QP.yuv" )
      else
        outputreconstructs+=( "\"\"" )
      fi
      outputbitstreams+=( "${OutputFolders[i]}/str-$name-$encfg-$QP.bin" )
      outputlogfiles+=( "${OutputFolders[i]}/log-$name-$encfg-$QP.txt" )
    else
      if [ -z "$SkipReconstruct" ]
      then
        outputreconstructs+=( "${OutputFolders[i]}/rec-$name-$encfg-$QP-$ReadStartFrame.yuv" )
      else
        outputreconstructs+=( "\"\"" )
      fi
      outputbitstreams+=( "${OutputFolders[i]}/str-$name-$encfg-$QP-$ReadStartFrame.bin" )
      outputlogfiles+=( "${OutputFolders[i]}/log-$name-$encfg-$QP-$ReadStartFrame.txt" )
    fi
  done

  # Intra Period
  IntraPeriod=""
  if [ "$encfg" == "RA" ]
  then
    IntraPeriod="-ip 64"
    case $name in
      "Campfire"|"RaceHorsesC"|"RaceHorses"|"SlideEditing") IntraPeriod="-ip 32"
      ;;
      "SlideShow") IntraPeriod="-ip 24"
      ;;
    esac
  fi

  # frame count
  if [ -z "$FrameCount" ]
  then
    if [ -z "$ReadStartFrame" ]
    then
      FrameCountArgument=""
    else
      FrameCountArgument="-fs $ReadStartFrame -f $ReadFrameCount --PrintHexPSNR"
    fi
  else
    FrameCountArgument="-f $FrameCount --PrintHexPSNR"
  fi

  # execute commands
  fullcommands=()
  for ((i = 0; i < $buildCount; i++)); do
    fullcommands+=( "${TestAppFolders[i]}/EncoderApp $configsincommand -b ${outputbitstreams[i]} -o ${outputreconstructs[i]} $FrameCountArgument $IntraPeriod -q $QP > ${outputlogfiles[i]} &" )
  done
  for ((i = 0; i < $buildCount; i++)); do
    echo ${fullcommands[i]}
  done
  cd $dataset/$class

  # monitor memory and processor usage
  while true
  do
    total=$(free -m | sed -n '2p' | awk '{print $2}')
    used=$(free -m | sed -n '2p' | awk '{print $3}')
    free=$(free -m | sed -n '2p' | awk '{print $4}')
    shared=$(free -m | sed -n '2p' | awk '{print $5}')
    buff=$(free -m | sed -n '2p' | awk '{print $6}')
    cached=$(free -m | sed -n '2p' | awk '{print $7}')
    # scale=2
    # percent=$(echo "(scale=2;$used*100/$total)" | bc | awk -F. '{print $2}')
    percent=$(echo "(($used*100)/$total)+1" | bc)
    # percent=$(echo "scale=2;{$used}/{$total}" | bc | awk -F. '{print $2}')
    # echo $used
    # echo $total
    # echo "percent:"
    # echo $percent
    process_count=$(pgrep -c EncoderApp | awk '{print $1}')
    # if [[ $percent -gt 80 || $process_count -ge $process_limit ]]
    if (( percent > 80 )) || (( process_count + buildCount >= process_limit ));
    then
        echo "usage too large, wait for 5 mins"
        sleep 5m
    else
        break
    fi
  done

  # for ((i = 0; i < $buildCount; i++)); do
  #   eval ${fullcommands[i]}
  # done
  # sleep 1m

done < "$txt"
# done
wait
echo "all tests done"
