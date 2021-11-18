# sirius-docker-compose-deploy
Apply all docker-compose yamls to docker host
# example of usage in pipeline
```
name: Deploy Dev VM1
# Restarts all changed docker containers in 'vm1' folder

on:
  push:
    branches: [ master ]
    paths:
    - 'vm1/**'

jobs:
  deploy:
    name: deploy
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Define environment variables
      run: cat common-environment-variables.sh >> $GITHUB_ENV
    - name: Print environment variables
      run: |
        for varname in $(awk -F= '{print $1}' common-environment-variables.sh)
        do
            printf "%s: %s\n" $varname ${!varname}
        done
    - name: Restart docker container on VM
      uses: swisschain/sirius-docker-compose-deploy@master
      env:
        ACTION: 'START'
        DOCKER_VM_HOST: ${{ env.DOCKER_VM_HOST_1 }}
        REPOSITORY_PATH_INFRASTRUCTURE: 'sirius-infra/docker-compose/vm1'
        REPOSITORY_PATH_SECRETS: 'sirius-infra-secrets'
        REPOSITORY_SERVICE_DIR: 'sirius/integrations/ethereum'
        SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        SSH_KNOW_HOST: ${{ env.SSH_KNOW_HOST_1 }}
```
