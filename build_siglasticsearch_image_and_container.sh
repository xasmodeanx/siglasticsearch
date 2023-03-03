#!/bin/bash
#Jason Barnett - xasmodeanx@gmail.com
#build_siglasticsearch_image_and_container.sh is a simple script
#to build and destroy elasticsearch/kibana containers and images

#check to see if this script is being run by root
#if [ `id -u` != "0" ]; then
#        echo "you must run $0 as root"
#        exit -1;
#fi

#If we got any argument on the command line, we will rebuild this container from scratch (must be connected to the internet)
if [ -z "$1" ]; then
	REBUILD=""
else
	REBUILD="true"
fi

#Get the total number of CPUs on this machine so we can dynamically allocate resources
#Depending on if this is a beef server or not
NUMHOSTCPUS="`nproc`"
if [ "${NUMHOSTCPUS}" -lt "8" ]; then
	#If we only had 7 or fewer CPUs available, set our elastic number of max CPUs to the min: 2, i.e. [0,1]
	CPUS="1"
	echo "Detected minimum CPU 0 through ${CPUS} CPU(s) available for the elastic container."
else
	#If we had 8 or more CPUs on this machine, use ~1 quarter of them for the elastic container, i.e. [0-X] where X is 1/4 nproc
	CPUS="`echo \"${NUMHOSTCPUS} / 4\" | bc`"
	echo "Detected CPU 0 through ${CPUS} CPU(s) available for the elastic container."
fi

#Similarly we need to also figure out how much memory we can give to the container as well. Minimum amount for elastic is 4G.
MAXHOSTMEM="`awk '/MemTotal/ {printf \"%.0f \n\", $2/1024/1024}' /proc/meminfo`" 
if [ "${MAXHOSTMEM}" -le "16" ]; then
	#Elastic requires a minimum of 4G, full stop.  Can't go lower.
	MEM="4"
	echo "Detected minimum memory allocation of ${MEM}G for container"
else
	#If we have more than 16G, we can safely take 1/3 of the memory and give to the container
	MEM="`echo \"${MAXHOSTMEM} / 3\" | bc`"
	echo "Detected memory allocation of ${MEM}G for container"
fi

#destroy the old containers and images
CONNAME="`docker container ls --all | grep siglasticsearch | awk '{print $1}'`"; echo ${CONNAME}; docker container kill ${CONNAME} 2>/dev/null; docker container rm -f ${CONNAME} 2>/dev/null
IMGNAME="`docker image ls --all | grep siglasticsearch | awk '{print $3}'`"; echo ${IMGNAME}; docker image rm ${IMGNAME} 2>/dev/null

#We need to have the vm.max_map_count setting in sysctl set to 262144, usually the default is too low
#Warn the user if the setting is not optimal.
if [ "`sysctl --all 2>/dev/null| grep vm.max_map_count| awk '{print $3}'`" -lt "262144" ]; then
	echo
	echo
	echo "============================================="
	echo "=         WARNING                           ="
	echo "============================================="
	echo "WARNING WARNING WARNING: sysctl reports vm.max_map_count < 262144! This will cause issues in production!"
	echo "This setting must be raised by running the following command AS ROOT (not sudo):"
	echo "sysctl -w vm.max_map_count=262144; echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
        echo "============================================="
        echo "=         WARNING                           ="
        echo "============================================="
	echo
	echo
	echo "Make the requested changes and re-run $0!"
	#exit 3
	echo "Ctrl-c this script now and fix it or wait 15 seconds to automatically attempt to continue on..."
	sleep 15
	echo
fi

#if we got any command line argument to this script, let's blow away the pre-made image and rebuilt it from scratch
if [ "${REBUILD}" ]; then
	#create the new image and container
	docker build -t siglasticsearch_image .
	#if the build succeeded, then let's save off a new image
	if ! [ "$?" -eq 0 ]; then
        	echo "Build did not succeed.  Cannot proceed."
        	exit 4
	fi
	
	#save off our image for offline use
	docker save -o siglasticsearch_image.docker siglasticsearch_image
	tar -zcvf siglasticsearch_image.tar.gz siglasticsearch_image.docker

	#remove all of the intermediate build images to save space and then import the offline container image
	#destroy the old containers and images
	CONNAME="`docker container ls --all | grep siglasticsearch | awk '{print $1}'`"; echo ${CONNAME}; docker container kill ${CONNAME} 2>/dev/null; docker container rm -f ${CONNAME} 2>/dev/null
	IMGNAME="`docker image ls --all | grep siglasticsearch | awk '{print $3}'`"; echo ${IMGNAME}; docker image rm ${IMGNAME} 2>/dev/null
	#unpack and import the image
        tar -zxvf siglasticsearch_image.tar.gz
        docker load -i siglasticsearch_image.docker
        #if the load was a failure, bail out
        if ! [ "$?" -eq 0 ]; then
                echo "Build did not succeed.  Cannot proceed."
                exit 5
        fi

#otherwise, load the pre-made image
elif [ -e "siglasticsearch_image.tar.gz" ]; then
	#unpack and import the image
	tar -zxvf siglasticsearch_image.tar.gz
	docker load -i siglasticsearch_image.docker

	#if the load was a failure, bail out
	if ! [ "$?" -eq 0 ]; then
                echo "Build did not succeed.  Cannot proceed."
                exit 2
	fi

#otherwise we can't proceed
else
	echo "Cannot proceed.  Can't find the offline docker image to import and the rebuild directive was not supplied as an argument to this script to make a new one."
	echo "To build a new image (while connected to the internet), call the following command:"
	echo "$0 rebuild"
	exit 6
fi

#invoke a container using the image we built
docker run --name siglasticsearch_container \
--net host -h siglasticsearch \
-d --restart always --cap-add SYS_TIME \
--memory ${MEM}G --cpuset-cpus="0-${CPUS}" \
-p 9200:9200 -p 5601:5601 \
--ulimit nofile=65535:65535 -e "bootstrap.memory_lock=true" --ulimit memlock=-1:-1 \
-e "xpack.security.enabled=true" \
-e "discovery.type=single-node" \
-e "TAKE_FILE_OWNERSHIP=true" \
-e "KBN_PATH_CONF=/usr/share/kibana/config" \
siglasticsearch_image

echo
echo
echo "Done.  To get a shell inside the container: "
echo "docker exec -it siglasticsearch_container /bin/bash"
echo
echo "You may now navigate to http://localhost:5601/kibana to access the WebUI (Kibana) for Elasticsearch"
echo "using username elastic and password found at siglasticsearch:/etc/elasticsearch/passwords"
echo
echo "Or see tests/sampledata/example_signals_search_request.sh to see how to perform queries programatically"
echo "Expect the container to take 2-5 minutes to start up if this is the first time it has ever been run."
echo

exit 0
