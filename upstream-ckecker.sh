#!/bin/bash

servers=("192.168.7.10:7000" "192.168.7.10:7070")
endpoint="/api/pub/status"
curentDate=`date +"%Y_%m_%d_%I_%M_%p"`
conf_file="/etc/nginx/conf.d/product.conf"
upstreamCheck (){
for server in "${servers[@]}"
do
    status=$(curl -k $server$endpoint | grep -i "success")

    if [ -n "$status" ]; then
        echo "`date`| Server $server: Status = $status" >> $curentDate-status.txt
        if grep -q "# server $server" "$conf_file"; then
            # Uncomment the server by removing the '#' character
            sed -i "s/# server $server /server $server /g" "$conf_file"
            echo "Server $server has been uncommented."
            nginx -s reload
        else
            echo "Server $server is already active."
        fi
       
    else
        echo "`date`| Server $server: Status = Failure" >> $curentDate-status.txt
        if grep -q "# server $server" "$conf_file"; then
                echo "Server $server is already commented out."
        else
                echo "Commenting out server $server."
                sed -i "s/server $server /# server $server /g" "$conf_file"
                echo "Server $server has been commented out."
                nginx -s reload
        fi

        
    fi

done
}

upstreamCheck
