# webmethods-apis-devops

DevOps sample project for performing CI/CD of APIs into the SoftwareAG API Gateway platform.

This project is closely based on the following 2 projects with extra modifications based on our own requirements:
 - [SoftwareAG API Gateway DevOps](https://github.com/SoftwareAG/webmethods-api-gateway-devops)
 - [API Gateway Staging](https://github.com/thesse1/webmethods-api-gateway-staging)

Project Status: DRAFT (in progress)

## Env vars

```bash
export APIGW_MYLOCALDEV_URL="http://apigatewaydev:5555"
export APIGW_MYLOCALDEV_DEPLOY_USER="Administrator"
echo -n "DEV ENV Administrator password: "; read -s password; export APIGW_MYLOCALDEV_DEPLOY_PASSWORD=$password
```

```bash
export APIGW_QA_URL="http://apigatewayqa:5555"
export APIGW_QA_DEPLOY_USER="Administrator"
echo -n "QA ENV Administrator password: "; read -s password; export APIGW_QA_DEPLOY_PASSWORD=$password
```

## Development (usually on your local or a dev server)

### Raw import the apis from git, as-is (no staging)

```bash
./gateway_import_export_utils.sh --import --api_name bookstore --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --import --api_name covid --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --import --api_name uszip --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --import --api_name sagtours --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD
```

### export the apis to save in git once work is done

```bash
./gateway_import_export_utils.sh --export --api_name bookstore --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --export --api_name covid --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --export --api_name uszip --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --export --api_name sagtours --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD
```

## CI

Build a package for an api with the build number
ie. bookstore-<version>.zip
And push it to an artifact repo...

NOTE: this should not be the Assets only...should be the full api project including the tests and the aliases etc... 
Because we'll need these artifacts in the CD portion.

## Deploy 

These should usually be automated using a build pipeline tool like Jenkins...

## deploy environment-staged apis

Get the api package deployed on artifact repo and perform the following:
- extracting, 
- modifying alias 
- package assets
- deploy
- perform extra api calls (ie. publish to portal)
- run tests


```bash
source common.sh; deploy_staged_api "bookstore" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
source common.sh; deploy_staged_api "covid" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
source common.sh; deploy_staged_api "uszip" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
source common.sh; deploy_staged_api "sagtours" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
```

### run tests

```bash
source common.sh; run_test_suite "bookstore" "all" "qa_environment.json"
source common.sh; run_test_suite "covid" "all" "qa_environment.json"
source common.sh; run_test_suite "uszip" "all" "qa_environment.json"
```