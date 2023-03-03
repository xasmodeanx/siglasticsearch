# siglasticsearch
## A Pre-Configured Container running: Elasticsearch and Kibana for use in Signal Analysis Applications

### Pre-requisites
1. Docker and docker-cli installed
2. Tool `bc and build-essential (gcc, make, etc)` installed
`sudo apt install gc build-essential`

### Creating the Siglasticsearch Image
1. Run the `build_siglasticsearch_image_and_container.sh` script and follow the on-screen directions.  This script will generate a .tar.gz file that can be taken to offline systems to load.

### Running the Siglasticsearch Container
1. This is already done for you by `build_siglasticsearch_image_and_container.sh`, or you can run it manually:
`docker run --name siglasticsearch_container \
--net host -h siglasticsearch \
-d --restart always --cap-add SYS_TIME \
--memory ${MEM}G --cpuset-cpus="0-${CPUS}" \
-p 9200:9200 -p 5601:5601 \
--ulimit nofile=65535:65535 -e "bootstrap.memory_lock=true" --ulimit memlock=-1:-1 \
-e "xpack.security.enabled=true" \
-e "discovery.type=single-node" \
-e "TAKE_FILE_OWNERSHIP=true" \
-e "KBN_PATH_CONF=/usr/share/kibana/config" \
siglasticsearch_image`
Where `${MEM}` specifies the maximum amount of memory you want to give to the Siglasticsearch container, and `${CPUS}` specifies the upper CPU limit.
NOTE: The first time the container is started up, it will prepare all of the indexes and settings specified by overlay/elasticsearch/autoconfig/  ; This process may take 2-5 minutes!  Subsequent container restarts will only take about 60 seconds for it to fully come up.

### Accessing
1. Open a web browser and navigate to http://localhost:5601/kibana
If you need the Admin password (the 'elastic' username/password), you can find it in the container at siglasticsearch:/etc/elasticsearch/passwords

### Known Issues and Considerations
1. This repo and script will generate a container that attached to the host network.  This is bad security practice.  You should create your own Docker network and attach it and give it an IP there so that it doesn't conflict with other containers and doesn't expose itself fully to the host network.
2. You should deploy this container behind a proxy OR enable TLS for Kibana.  Documentation for enabling TLS for Kibana is at  https://www.elastic.co/guide/en/elasticsearch/reference/8.6/security-basic-setup-https.html#encrypt-kibana-browser - if you do this, you will need to modify your /etc/kibana/kibana.yml file and uncomment the lines dealing with Cookies.
3. If you would like to embed the kibana page in an iframe, you can pass the anonymous authentication credentials along with the request to skip the login screen.  See example here: `<iframe src="https://localhost:5601/kibana/app/monitoring?auth_provider_hint=anonymous1#/elasticsearch/nodes?embed=true&_g=(....)" height="600" width="800"></iframe>`
