# Usage examples for single tasks
## Start local Keycloak instance
Start Keycloak docker container

    docker run -d --name keycloak \
        --network testnet \
        --rm \
        -p 8881:8080 \
        -e KEYCLOAK_USER=admin \
        -e KEYCLOAK_PASSWORD=admin \
        jboss/keycloak:7.0.0

Import realm

    ./keycloak-tool.sh import-realm \
        -i http://$HOSTNAME:8881/auth \
        -u admin \
        -p admin \
        -f realm.json

## Get access token
Get client's access token (confidential access type)

    ./keycloak-tool.sh get-client-access-token \
        -i http://$HOSTNAME:8881/auth \
        -r development \
        -u admin \
        -p admin \
        -c dev-private

Get user's access token (public access type)

    ./keycloak-tool.sh get-user-access-token \
        -i http://$HOSTNAME:8881/auth \
        -r development \
        -c dev-public \
        -u test1 \
        -p geslo
        
## Role mappings
### Realm level
Print realm role mappings
        
    ./keycloak-tool.sh print-realm-role-mappings \
        -i http://$HOSTNAME:8881/auth \
        -r development \
        -u admin \
        -p admin \
        -k service-account-dev-private

Assign realm role mappings

    ./keycloak-tool.sh assign-realm-role-mappings \
        -i http://$HOSTNAME:8881/auth \
        -r development \
        -u admin \
        -p admin \
        -k service-account-dev-private \
        -f realm-roles.json

### Client level
Print client role mappings
        
    ./keycloak-tool.sh print-client-role-mappings \
        -i http://$HOSTNAME:8881/auth \
        -r development \
        -u admin \
        -p admin \
        -c media-archive \
        -k service-account-dev-private

Assign client role mappings

    ./keycloak-tool.sh assign-client-role-mappings \
        -i http://$HOSTNAME:8881/auth \
        -r development \
        -u admin \
        -p admin \
        -c media-archive \
        -k service-account-dev-private \
        -f client-roles_media-archive.json

## Client secret
Generate client secret

    ./keycloak-tool.sh generate-client-secret \
       -i http://$HOSTNAME:8881/auth \
       -r development \
       -u admin \
       -p admin \
       -c dev-private

## Users
Export users
    
    ./keycloak-tool.sh export-users \
        -i http://$HOSTNAME:8881/auth \
        -r development \
        -u admin \
        -p admin

Import users

    ./keycloak-tool.sh import-users \
            -i http://$HOSTNAME:8881/auth \
            -r development \
            -u admin \
            -p admin \
            -f users.json

Import users with passwords and assigned groups

    ./keycloak-tool.sh import-users-passwords \
            -i http://$HOSTNAME:8881/auth \
            -r development \
            -u admin \
            -p admin \
            -f users-passwords.json