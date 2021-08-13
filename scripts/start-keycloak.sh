#!/bin/bash

if [ -z "$1" ] && [ -z "$2" ]
then
      echo "Usage: start-keycloak.sh <path-to-config> <data-set>"
      exit 0
fi

script_full_path=$(dirname "$0")

conf_file=$1
data_set=$2

json_files_dir="$(dirname "$conf_file")/$data_set"

file_realm="$json_files_dir/realm.json"
file_users="$json_files_dir/users-passwords.json"
file_realm_role_mappings="$json_files_dir/realm-roles.json"
file_client_role_mappings="$json_files_dir/client-roles.json"

# vars to be read from config
keycloak_docker_instance=
keycloak_port=
keycloak_version=
dbvendor=
username=
password=
client_dev_username=
client=
client_dev=
docker_network="testnet"

# shellcheck source=/dev/null
source "$conf_file"

url="http://pingvinx:$keycloak_port/auth"

if  docker ps -a | grep -q $keycloak_docker_instance ; then
  echo "Docker container \"$keycloak_docker_instance\" is already running."
  exit 0
fi

echo -e "\033[1;34mStarting Keycloak instance.\033[0m"
docker run -d --name $keycloak_docker_instance \
    --network $docker_network \
    --rm \
    -p $keycloak_port:8080 \
    -e KEYCLOAK_USER=$username \
    -e KEYCLOAK_PASSWORD=$password \
    -e DB_VENDOR=$dbvendor \
    jboss/keycloak:$keycloak_version

# function validates, if url exists
function validate_url () {
    header=$(curl -s --head "$1" | head -n 1 | grep "HTTP/[1-3].[0-9] [23]..")
  if [[ $header ]]; then
    echo "true"
  fi
}

retries=30
echo -n "Waiting for Keycloak server "
until [ "$(validate_url "$url/")" ] || [ $retries -eq 0 ]; do
    echo -n "."
    ((retries--))
    sleep 1
done
echo

if [ $retries -eq "0" ]; then
    echo -e "\033[0;31mAttempt to start Keycloak has failed.\033[0m"
    docker kill $keycloak_docker_instance
    exit
fi
echo -e "\033[0;32mKeycloak is up and running.\033[0m (port: $keycloak_port)"
echo "$url/"

echo "Import realm."
"$script_full_path/keycloak-tool.sh" import-realm \
    -i $url \
    -u $username \
    -p $password \
    -f "$file_realm"

echo "Import users."
"$script_full_path/keycloak-tool.sh" import-users-passwords \
        -i $url \
        -r "$realm" \
        -u $username \
        -p $password \
        -f "$file_users"

echo "Assign realm role mappings."
"$script_full_path/keycloak-tool.sh" assign-realm-role-mappings \
    -i $url \
    -r "$realm" \
    -u $username \
    -p $password \
    -k $client_dev_username \
    -f "$file_realm_role_mappings"

echo "Assign client role mappings."
"$script_full_path/keycloak-tool.sh" assign-client-role-mappings \
    -i $url \
    -r "$realm" \
    -u $username \
    -p $password \
    -c $client \
    -k $client_dev_username \
    -f "$file_client_role_mappings"

echo -ne "$client_dev secret: "
"$script_full_path/keycloak-tool.sh" generate-client-secret \
   -i $url \
   -r "$realm" \
   -u $username \
   -p $password \
   -c $client_dev \
  | jq -r '.value'
