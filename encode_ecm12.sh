#读取 $1 sort_list.txt 的每行，按照顺序配置视频文件config，然后执行EncoderApp
#记得把编译好的EncoderApp放到和这个文件同一个文件夹内
#把参考软件中的cfg文件夹也复制到这里

#目前的问题是它不会检测当前已经跑了多少个进程，然后系统内存不足就卡住了
#一个进程大约要吃8GB内存

#!/bin/bash
help()
{
  echo "Arguments:"
  echo "-t|--test_app_folder TestAppFolder"
  echo "-s|--sort SortListFile"
  echo "-o|--output OutputFolder (default: $home_folder/outputs/example)"
  echo "-d|--dataset DatasetFolder (default: /data/xcy_test)"
  # echo "-r|--reference_app_folder ReferenceAppFolder (default: \$pwd/App_ECM10)"
  echo "-f|--frame_count FrameCount (run whole sequences if absent)" 
  echo "-b|--build_label BuildLabel"
  echo "If BuildLabel is present,"
  echo "1) OutputFolder will be set as $home_folder/outputs/BuildLabel;"
  echo "2) TestAppFolder will be set as \$pwd/App_BuildLabel;"
  echo "3) -o and -t will be ignored."
}

if [[ $# -eq 0 ]]
then
  help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--sort)
      txt="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--output)
      testfield="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--dataset)
      dataset="$2"
      shift # past argument
      shift # past value
      ;;
    # -r|--reference_app_folder)
    #   ReferenceAppFolder="$2"
    #   shift # past argument
    #   shift # past value
    #   ;;
    -t|--test_app_folder)
      TestAppFolder="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--frame_count)
      FrameCount="$2"
      shift # past argument
      shift # past value
      ;;
    -b|--build_label)
      BuildLabel="$2"
      shift # past argument
      shift # past value
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

# txt=$1  #sort_list.txt文件路径
# testfield=$2  #输出的目标文件路径，里面是class?文件夹
# dataset=$3  #视频文件路径，里面是class?文件夹

originaldirectory=$(pwd)
home_folder="/data/hongdong.qin"
cfgdirectory="$home_folder/ECM-12/cfg"

#设置缺省路径以及将$2和$3转换成绝对路径
if [ -z "$BuildLabel" ]
then
  if [ -z "$testfield" ]
  then
    testfield="$home_folder/outputs/example"
  elif [ "${testfield:0:1}" != "/" ]
  then
    testfield="$home_folder/outputs/$testfield"
  fi
  if [ -z "$TestAppFolder" ]
  then
    echo "You must provide test app folder with -t or --test_app_folder"
    help
    exit 1
  elif [ "${TestAppFolder:0:1}" != "/" ]
  then
    TestAppFolder="$originaldirectory/$TestAppFolder"
  fi
else
  testfield="$home_folder/outputs/$BuildLabel"
  TestAppFolder="$originaldirectory/App_$BuildLabel"
fi

if [ -z "$dataset" ]
then
    dataset="/data/xcy_test"
elif [ "${dataset:0:1}" != "/" ]
then
    dataset="$originaldirectory/$dataset"
fi

echo "Process $txt line by line." 
# echo "$testfield"
# echo "$dataset"
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
    
    echo "$encfg $ClassName $Class $name $QP1 $QP"

    if [[ "$encfg" != "RA" ]] && [[ "$encfg" != "LP" ]] && [[ "$encfg" != "LB" ]] && [[ "$encfg" != "AI" ]]
    then
        echo "continue"
        continue
    fi

    echo "=============================== a new processing core ============================================="
	echo "Check $encfg $Class $name $QP"

  OutputFolder="$testfield/$Class/$name"
  $(mkdir -p $OutputFolder)

  cd $originaldirectory

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
  configfilelist="$encodecfg"

  # configurations per-class
  # JVET-Y2017 Section 6
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
  configfilelist="$configfilelist $classcfg $sequencecfg"
  # echo $configfilelist
  
  # add configuration files (absolute path) to command
  configfilearray=($configfilelist)
  configsincommand=""
  for i in "${configfilearray[@]}"
  do
    configsincommand="$configsincommand -c $i"
  done

  # other files
  if [ -z "$ReadStartFrame" ]
  then
    outputbitstream="$OutputFolder/str-$name-$encfg-$QP.bin"
    outputreconstruct="$OutputFolder/rec-$name-$encfg-$QP.yuv"
    outputlogfile="$OutputFolder/log-$name-$encfg-$QP.txt"
  else
    outputbitstream="$OutputFolder/str-$name-$encfg-$QP-$ReadStartFrame.bin"
    outputreconstruct="$OutputFolder/rec-$name-$encfg-$QP-$ReadStartFrame.yuv"
    outputlogfile="$OutputFolder/log-$name-$encfg-$QP-$ReadStartFrame.txt"
  fi
  # echo $outputbitstream
  # echo $outputreconstruct
  # echo $outputlogfile

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

  # 在视频文件夹内执行代码（因为懒得改cfg里面的视频文件路径）
  # fullcommand="$originaldirectory/EncoderApp $configsincommand -b $outputbitstream -o $outputreconstruct -q $QP > $outputlogfile &"
  # fullcommand="$originaldirectory/App/EncoderApp $configsincommand -b $outputbitstream -o $outputreconstruct -q $QP > $outputlogfile &"
  fullcommand="$TestAppFolder/EncoderApp $configsincommand -b $outputbitstream -o $outputreconstruct $FrameCountArgument $IntraPeriod -q $QP > $outputlogfile &"
  echo "Executing the following command:"
  echo $fullcommand
  cd $dataset/$Class
  # $($fullcommand)
  # echo $(pwd)

  # 监控进程数量和内存占用情况
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
    if [[ $percent -gt 80 || $process_count -ge $cores ]]
    then
        echo "usage too large, wait for 5 mins"
        sleep 5m
    else
        break
    fi
  done

  
  eval $fullcommand
  sleep 1m

done < "$txt"
# done
wait
echo "all tests done"


