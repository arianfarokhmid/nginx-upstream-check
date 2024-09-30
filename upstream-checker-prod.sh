#!/bin/bash

servers=("192.168.19.81:7000" "192.168.19.82:7000")
endpoint="/api/pub/status"
currentDate=`date +"%Y_%m_%d_%I_%M_%p"`
conf_file="/etc/nginx/conf.d/dispatch.conf"
upstreamCheck (){
for server in "${servers[@]}"
do
    status=$(curl -k $server$endpoint | grep -i "success")

    if [ -n "$status" ]; then
        echo "`date`| Server $server: Status = $status" #>> $currentDate-status.txt
        if grep -q "# server $server" "$conf_file"; then
            # Uncomment the server by removing the '#' character
            sed -i "s/# server $server /server $server /g" "$conf_file"
            echo "Server $server has been uncommented."
            nginx -s reload
        else
            echo "Server $server is already active."
        fi
        #sed -i "s/# server $server /server $server /g" "$conf_file"
    else
        echo "`date`| Server $server: Status = Failure" #>> $currentDate-status.txt
        if grep -q "# server $server" "$conf_file"; then
                echo "Server $server is already commented out."
        else
                echo "Commenting out server $server."
                sed -i "s/server $server /# server $server /g" "$conf_file"
                echo "Server $server has been commented out."
                nginx -s reload
        fi

        #sed -i "s/server $server /# server $server /g" /etc/nginx/conf.d/product.conf
        #if [ $? -eq 0 ];then
        #nginx -s reload
        #fi     
    fi

done
}

upstreamCheck > ./logs/$currentDate-status.txt

if [ $? -eq 0 ];then
        cd ./logs && ls -t | sed -e '1,10d' | xargs -I {} rm -f {}
else
        exit 1
fi
