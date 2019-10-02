# Start Keycloak for local testing
To start Keycloak for testing purposes there is script [start-keycloak.sh](scripts/start-keycloak.sh).

It starts docker image and after that it completes these configurations:
- imports realm
- imports users
- assigns realm role mappings
- assigns client role mappings
- generates secret for development client

It is good idea to put absolute path to the script into `~/.bashrc` file as alias.

    alias start-keycloak.sh=/path/to/start-keycloak.sh

Then we might call this script from anywhere with command like this:

    start-keycloak.sh <PATH_TO_CONFIG_FILE> <DATA_SET_NAME>

## Configuration
The script uses external config file to set variables.

Config file example:

    keycloak_docker_instance="keycloak"
    
    keycloak_port="8881"
    keycloak_version="7.0.0"
    
    username="admin"
    password="admin"
    
    client="my-client"
    
    $client_dev_username="service-account-dev-private"
    client_dev="dev-private"

Aditionally we need to provide data for import. We can specify different data sets. Each one has to be in separate 
subdirectory on path where is config file.

Required files in each dataset are:
- `realm.json` - General realm data (exported from predefined Keycloak).
- `realm-roles.json`  - Realm role mappings (exported from predefined Keycloak using 
                        `keycloak-tool.sh print-realm-role-mappings`).
- `client-roles.json` - Client role mappings (exported from predefined Keycloak using 
                        `keycloak-tool.sh print-client-role-mappings `).
- `users-passwords.json` - Data for users, their group memberships and passwords.

Example of configuration directory structure:

    .
    ├── my-data-set
    |   ├── client-roles.json
    |   ├── realm.json
    |   ├── realm-roles.json
    |   ├── user-passwords.json
    ├── my-preferences.conf

Example of `users-passwords.json` file content:

    [
      {
        "userData": {
          "username": "test1",
          "firstName": "T1",
          "lastName": "Test",
          "email": "test1@example.com",
          "enabled": true,
          "emailVerified": true
        },
        "userPassword": {
          "type": "password",
          "temporary": false,
          "value": "P@ssw0rd"
        },
        "userGroups": [
          "users-group"
        ]
      },
      {
        "userData": {
          "username": "test2",
          "firstName": "T2",
          "lastName": "Test",
          "email": "test2@example.com",
          "enabled": true,
          "emailVerified": true
        },
        "userPassword": {
          "type": "password",
          "temporary": false,
          "value": "P@ssw0rd"
        },
        "userGroups": [
          "users-group"
        ]
      }
    ]