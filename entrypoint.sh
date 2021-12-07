#!/bin/sh

# exit when any command fails
set -e

echo create ssh key
echo $SSH_PRIVATE_KEY | base64 -d > /tmp/id_rsa
chmod 400 /tmp/id_rsa
echo create ssh know host file
echo $SSH_KNOW_HOST > /tmp/known_hosts
cat /tmp/known_hosts
echo run command
echo DOCKER_VM_HOST=$DOCKER_VM_HOST
ssh $DOCKER_VM_HOST -i /tmp/id_rsa -o UserKnownHostsFile=/tmp/known_hosts << EOF
  hostname
  # redefine home directory
  HOME_DIRECTORY=\$(pwd)
  echo HOME_DIRECTORY=\$HOME_DIRECTORY
  # define functions
  start_docker() {
    echo run service
    docker-compose pull
    docker-compose up -d
    echo sleep for 2 seconds
    sleep 2
    echo print last logs
    docker-compose logs --tail 100
  }
  stop_docker() {
    echo stop service
    docker-compose stop
  }
  down_docker() {
    echo delete service
    docker-compose down
  }
  restart_docker() {
    echo restart service
    docker-compose restart
  }
  echo pull secrets repository
  cd $REPOSITORY_ROOT_SECRETS/
  git pull
  if [ -f ./secrets.json ];then
    echo found common secrets file
    ls -la ./secrets.json
  fi
  # REPOSITORY_ROOT_INFRASTRUCTURE to avoid git pull failure due to REPOSITORY_PATH_INFRASTRUCTURE doesn't exist
  echo pull main repository \($REPOSITORY_ROOT_INFRASTRUCTURE $REPOSITORY_PATH_INFRASTRUCTURE\)
  cd ../$REPOSITORY_ROOT_INFRASTRUCTURE
  git pull
  cd ../$REPOSITORY_PATH_INFRASTRUCTURE
  # if "$REPOSITORY_SERVICE_DIR" found then we apply to one component, otherwise to all components
  if [ -n "$REPOSITORY_SERVICE_DIR" ];then
    echo REPOSITORY_SERVICE_DIR defined - $REPOSITORY_SERVICE_DIR
    DCD=$REPOSITORY_SERVICE_DIR
  else
    echo searching for docker-compose.yaml files
    DCD=\$(find . -name docker-compose.yaml | awk -Fdocker-compose.yaml '{print \$1}' | awk -F. '{print \$2}')
  fi
  echo list of dirs \$DCD
  for DIR_NAME in \$DCD
  do
    echo
    echo   - = [ \$DIR_NAME ] = -
    if [ -d \$DIR_NAME ];then
      cd \$DIR_NAME
      pwd
      echo ls secrets dir \$HOME_DIRECTORY/$REPOSITORY_ROOT_SECRETS/\$DIR_NAME
      ls -la \$HOME_DIRECTORY/$REPOSITORY_ROOT_SECRETS/\$DIR_NAME/
      # create a symlink for infra components to .env file (instead of copying it)
      if [ -f \$HOME_DIRECTORY/$REPOSITORY_ROOT_SECRETS/\$DIR_NAME/.env ];then
        echo found .env file
        if [ -f .env ];then
          echo file or symlink exist
        else
          echo create symlink
          ln -s \$HOME_DIRECTORY/$REPOSITORY_ROOT_SECRETS/\$DIR_NAME/.env ./.env
        fi
      fi
      # show if we found 'secrets.json'
      if [ -f \$HOME_DIRECTORY/$REPOSITORY_ROOT_SECRETS/\$DIR_NAME/secrets.json ];then
        echo found service secrets file
        ls -la \$HOME_DIRECTORY/$REPOSITORY_ROOT_SECRETS/\$DIR_NAME/secrets.json
      fi
      ls -la
      if [ "$ACTION" = "START" ];then
        start_docker;
      fi
      if [ "$ACTION" = "STOP" ];then
        stop_docker;
      fi
      if [ "$ACTION" = "DOWN" ];then
        down_docker;
      fi
      if [ "$ACTION" = "RESTART" ];then
        restart_docker;
      fi
    else
      echo \$DIR_NAME doesn\'t exist
    fi
    cd \$HOME_DIRECTORY/$REPOSITORY_PATH_INFRASTRUCTURE
  done
  echo remove orphan docker images
  docker image prune -af
EOF
# remove private key
rm /tmp/id_rsa
