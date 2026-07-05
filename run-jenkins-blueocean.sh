docker run \
  --name jenkins-blueocean \
  --restart=on-failure \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume /mnt/data/jenkins/data:/var/jenkins_home \
  --volume /mnt/data/jenkins/certs:/certs/client:ro \
  docker.io/frenoid/jenkins-blueocean:2.555.3-jdk21