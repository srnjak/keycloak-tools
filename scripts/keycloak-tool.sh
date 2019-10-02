#!/bin/bash

check_file() {
  if [ -z "$filename" ]; then
    echo "No file specified."
    exit 1
  fi

  if [ ! -f "$filename" ]; then
    echo "File '$filename' not found!"
    exit 1
  fi
}

get_token() {
  TKN=$(curl -s \
    -d "client_id=admin-cli" \
    -d "username=$username" \
    -d "password=$password" \
    -d "grant_type=password" \
    "$url/realms/master/protocol/openid-connect/token" \
    | jq -r '.access_token')
}

get_user_access_token() {
  curl -s \
    -d "client_id=$client" \
    -d "username=$username" \
    -d "password=$password" \
    -d "grant_type=password" \
    "$url/realms/$realm/protocol/openid-connect/token" \
    | jq -r '.access_token'
}

get_client_secret() {
  get_token
  find_client_id "$client"

  curl -s -X GET \
    -H "Authorization: bearer $TKN" \
    -H "Content-Type: application/json" \
    "$url/admin/realms/$realm/clients/$client_id/client-secret" \
    | jq '.'
}

get_client_access_token() {

  client_secret=$(
    get_client_secret | jq -r '.value'
  )

  auth=$(
    printf "%s" "$client:$client_secret" | base64
  )

  curl -s -X POST \
    -H "Authorization: Basic $auth" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    "$url/realms/$realm/protocol/openid-connect/token" \
    | jq -r '.access_token'

}

find_user_id() {
  username=$1

  user_id=$(curl -s \
    -H "Authorization: bearer $TKN" \
    "$url/admin/realms/$realm/users?username=$username" \
    | jq '.[0]' | jq -r '.id')
}

find_client_id() {
  clientname=$1

  client_id=$(curl -s \
    -H "Authorization: bearer $TKN" \
    "$url/admin/realms/$realm/clients?clientId=$clientname" \
    | jq '.[0]' | jq -r '.id')
}

find_group_id() {
  groupname=$1

  group_id=$(curl -s \
    -H "Authorization: bearer $TKN" \
    "$url/admin/realms/$realm/groups?name=$groupname" \
    | jq '.[0]' | jq -r '.id')
}

export_realm() {
  curl -X POST \
    -H "Authorization: bearer $TKN" \
    -H "Content-Type: application/json" \
    "$url/admin/realms/$realm/partial-export?exportClients=true&exportGroupsAndRoles=true" \
    | jq '.'
}

import_realm() {
  check_file

  get_token

  curl -X POST \
    -H "Authorization: bearer $TKN" \
    -H "Content-Type: application/json" \
    -d @"$filename" \
    "$url/admin/realms"
}

print_client_user_role_mappings() {
  get_token
  find_user_id "$user"
  find_client_id "$client"

  curl -s \
    -H "Authorization: bearer $TKN" \
    "$url/admin/realms/$realm/users/$user_id/role-mappings/clients/$client_id/" \
    | jq '.'
}

assign_client_user_role_mappings() {
  check_file

  get_token
  find_user_id "$user"
  find_client_id "$client"

  curl -X POST \
    -H "Authorization: bearer $TKN" \
    -H "Content-Type: application/json" \
    -d @"$filename" \
    "$url/admin/realms/$realm/users/$user_id/role-mappings/clients/$client_id"
}

print_realm_user_role_mappings() {
  get_token
  find_user_id "$user"

  curl -s \
    -H "Authorization: bearer $TKN" \
    "$url/admin/realms/$realm/users/$user_id/role-mappings/realm/" \
    | jq '.'
}

assign_realm_user_role_mappings() {
  check_file

  get_token
  find_user_id "$user"

  curl -X POST \
    -H "Authorization: bearer $TKN" \
    -H "Content-Type: application/json" \
    -d @"$filename" \
    "$url/admin/realms/$realm/users/$user_id/role-mappings/realm"
}

generate_client_secret() {
  get_token
  find_client_id "$client"

  curl -s -X POST \
    -H "Authorization: bearer $TKN" \
    -H "Content-Type: application/json" \
    "$url/admin/realms/$realm/clients/$client_id/client-secret" \
    | jq '.'
}

export_users() {
  get_token

  curl -s -X GET \
  "$url/admin/realms/$realm/users" \
  -H "authorization: bearer $TKN" \
  | jq '.'
}

import_users() {
  check_file
  get_token

  users=$(cat "$filename")

  for row in $(echo "${users}" | jq -r '.[] | @base64'); do

    _jq() {
      echo "${row}" | base64 --decode | jq -r "${1}"
    }

    curl -s -X POST \
      "$url/admin/realms/$realm/users" \
      -H "authorization: bearer $TKN" \
      -H 'content-type: application/json' \
      -d "$(_jq '.')"
  done
}

import_users_passwords() {
  check_file
  get_token

  users=$(cat "$filename")

  for row in $(echo "${users}" | jq -r '.[] | @base64'); do

    _jq() {
      echo "${row}" | base64 --decode | jq -r "${1}"
    }

    userData=$(_jq '.userData')
    userPassword=$(_jq '.userPassword')
    user=$(_jq '.userData.username')
    userGroups=$(_jq '.userGroups')

    curl -s -X POST \
      "$url/admin/realms/$realm/users" \
      -H "authorization: bearer $TKN" \
      -H 'content-type: application/json' \
      -d "$userData"

    find_user_id "$user"

    if [[ "$userPassword" != "null" ]]; then
        curl -s -X PUT \
            "$url/admin/realms/$realm/users/$user_id/reset-password" \
            -H "authorization: bearer $TKN" \
            -H 'content-type: application/json' \
            -d "$userPassword"
    fi

    if [[ "$userGroups" != "null" ]]; then

        for group_row in $(echo "${userGroups}" | jq -r '.[] | @base64'); do

        _jq2() {
            echo "${group_row}" | base64 --decode
        }

        group=$(_jq2)

        find_group_id "$group"

        curl -s -X PUT \
            "$url/admin/realms/$realm/users/$user_id/groups/$group_id" \
            -H "authorization: bearer $TKN" \
            -H 'content-type: application/json'
        done
    fi
  done
}

## MAIN
me=$(basename "$0")
verbose=0

usage() {
  echo "Script for manipulating mappings of client-level roles to the user role in Keycloak."
  echo
  echo "usage: $me <COMMAND> <OPTIONS>"
  echo
  echo "COMMANDS"
  echo -e "\t get-user-access-token"
  echo -e "\t\t Get JWT token for user. (Based on username.)"
  echo
  echo -e "\t get-client-access-token"
  echo -e "\t\t Get JWT token for client. (Based on client id)"
  echo
  echo -e "\t export-realm"
  echo -e "\t\t Export of existing realm into a JSON."
  echo
  echo -e "\t import-realm"
  echo -e "\t\t Import realms from json file."
  echo
  echo -e "\t export-users"
  echo -e "\t\t Export users of specified realm into a JSON."
  echo
  echo -e "\t import-users"
  echo -e "\t\t Import users from json file into specified realm."
  echo
  echo -e "\t import-users-passwords"
  echo -e "\t\t Import users along with passwords from json file into specified realm."
  echo
  echo -e "\t print-client-role-mappings"
  echo -e "\t\t Print the client-level role mappings for the user."
  echo
  echo -e "\t print-realm-role-mappings"
  echo -e "\t\t Print the realm-level role mappings for the user."
  echo
  echo -e "\t assign-client-role-mappings"
  echo -e "\t\t Add client-level roles to the user role mapping."
  echo
  echo -e "\t assign-realm-role-mappings"
  echo -e "\t\t Add realm-level roles to the user role mapping."
  echo
  echo -e "\t generate-client-secret"
  echo -e "\t\t Generate the client secret."
  echo
  echo -e "\t get-client-secret"
  echo -e "\t\t Get the client secret."
  echo
  echo "OPTIONS"
  echo -e "\t -i <url>, --url <url>"
  echo -e "\t\t Url of Keycloak instance."
  echo
  echo -e "\t -u <username>, --username <username>"
  echo -e "\t\t Username for login into master realm."
  echo
  echo -e "\t -p <password>, --password <password>"
  echo -e "\t\t Password for login into master realm."
  echo
  echo -e "\t -r <realm>, --realm <realm>"
  echo -e "\t\t Keycloak realm."
  echo
  echo -e "\t -k <user>, --user <user>"
  echo -e "\t\t Name of the user."
  echo
  echo -e "\t -c <client>, --client <client>"
  echo -e "\t\t Authentication client."
  echo
  echo -e "\t -f <filename>, --file <filename>"
  echo -e "\t\t Name of the file to read from."
  echo
  echo -e "\t -v"
  echo -e "\t\t Verbose output."
  echo
  echo -e "\t -h, --help"
  echo -e "\t\t Shows this manual usage page."
}

command=$1;
shift

# read options
while [ "$1" != "" ]; do
  case $1 in
    -i | --url )
      shift
      url=$1
      ;;

    -u | --username )
      shift
      username=$1
      ;;

    -p | --password )
      shift
      password=$1
      ;;

    -r | --realm )
      shift
      realm=$1
      ;;

    -k | --user )
      shift
      user=$1
      ;;

    -c | --client )
      shift
      client=$1
      ;;

    -f | --file )
      shift
      filename=$1
      ;;

    -v )
      verbose=1
      ;;

    -h | --help )
      usage
      exit
      ;;

    * )
      usage
      exit 1
  esac
  shift
done

if [ $verbose = 1 ]; then
  set -x
fi

# execute command
case $command in
  get-user-access-token )
    get_user_access_token
    ;;

  get-client-access-token )
    get_client_access_token
    ;;

  export-realm )
    export_realm
    ;;

  import-realm )
    import_realm
    ;;

  export-users )
    export_users
    ;;

  import-users )
    import_users
    ;;

  import-users-passwords )
    import_users_passwords
    ;;

  print-client-role-mappings )
    print_client_user_role_mappings
    ;;

  print-realm-role-mappings )
    print_realm_user_role_mappings
    ;;

  assign-client-role-mappings )
    assign_client_user_role_mappings
    ;;

  assign-realm-role-mappings )
    assign_realm_user_role_mappings
    ;;

  generate-client-secret )
    generate_client_secret
    ;;

  get-client-secret )
    get_client_secret
    ;;

  -h | --help )
    usage
    exit
    ;;

  * )
    usage
    exit 1
esac

set +x