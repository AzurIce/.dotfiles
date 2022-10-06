#!/bin/bash
sleep 1 # wait for waybar to be launched
    running=`ps -ef|grep syncthingtray|grep -v "grep"|grep -v "launch_syncthingtray.sh"|wc -l`
# if [ "$is_syncthingtray_ServerExist" = "0" ]; then
#     echo "syncthingtray_server not found" > /dev/null 2>&1
# #   exit;
# elif [ "$is_syncthingtray_ServerExist" = "1" ]; then
#     killall syncthingtray
# fi

echo "$running"
if [ "$running" -gt 0 ]; then
    killall syncthingtray
fi

syncthingtray --wait &

# echo "$running"
# while [ "$running" -le "0" ]
# do
#     running=`ps -ef|grep syncthingtray|grep -v "grep"|grep -v "launch_syncthingtray.sh"|wc -l`
#     syncthingtray &
#     sleep 1
# done

# syncthingtray --wait &
