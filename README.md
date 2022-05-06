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

### Import the APIs from git into development APIGateway (no staging)

This is usually something you do at the begining of your work to make sure you work on the latest version of the API based on what's in GIT (especially to accound for other people having possibly added new policies etc...)

```bash
./dev_import_export.sh --import --api_project bookstore --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --import --api_project covid --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --import --api_project uszip --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --import --api_project sagtours --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --import --api_project helloapi --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD
```

### Save the APIs in git once work is done on the development APIGateway

This is an incremental operation, as work gets done... and especially at the end of the work to make sure everything gets saved in GIT.

```bash
./dev_import_export.sh --export --api_project bookstore --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --export --api_project covid --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --export --api_project uszip --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --export --api_project sagtours --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD

./dev_import_export.sh --export --api_project helloapi --apigateway_url $APIGW_MYLOCALDEV_URL --username $APIGW_MYLOCALDEV_DEPLOY_USER --password $APIGW_MYLOCALDEV_DEPLOY_PASSWORD
```

## Deployment - Option 1 - CD only, directly from Git code (without storing in artifact repo)

In this option, we don't store a "build" in an artifact repo...we simply push the artifact in git into the target env...
### deploy

```bash
sh deploy_apiproject.sh --api_project "bookstore" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
sh deploy_apiproject.sh --api_project "covid" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
sh deploy_apiproject.sh --api_project "uszip" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
sh deploy_apiproject.sh --api_project "sagtours" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
sh deploy_apiproject.sh --api_project "helloapi" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
```

## Deployment - Option 2 - CI/CD (with storing in artifact repo)

In this option, we first store a "build" in an artifact repo...
And then, in a deploy stage, we push the build artifact to the target env...

### CI + storing in artifact repo

Build a package for an api project with the build number, and push it to a central artifact repo location (here a local folder, but could be nexus or other)

```bash
sh package_apiproject.sh --api_project "bookstore" --build_version "1.0.1"
sh package_apiproject.sh --api_project "covid" --build_version "1.0.1"
sh package_apiproject.sh --api_project "uszip" --build_version "1.0.1"
sh package_apiproject.sh --api_project "sagtours" --build_version "1.0.1"
sh package_apiproject.sh --api_project "helloapi" --build_version "1.0.1"
```

### Deploy to target environment

Get the api package deployed on artifact repo and perform the following:
- extracting, 
- modifying alias 
- package assets
- deploy
- perform extra api calls (ie. publish to portal)
- run tests

```bash
sh deploy_apiproject.sh --api_project_package "../staged/bookstore-1.0.1.zip" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD

sh deploy_apiproject.sh --api_project_package "../staged/covid-1.0.1.zip" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD

sh deploy_apiproject.sh --api_project_package "../staged/uszip-1.0.1.zip" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD

sh deploy_apiproject.sh --api_project_package "../staged/sagtours-1.0.1.zip" --stagename "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
```

## Run API Tests

```bash
sh test_apiproject.sh --api_project "bookstore" --build_version "1.0.1" --stagename "qa" --testenvvars "apigateway_baseurl_qa=$APIGW_QA_URL"
sh test_apiproject.sh --api_project "covid" --build_version "1.0.1" --stagename "qa" --testenvvars "apigateway_baseurl_qa=$APIGW_QA_URL"
sh test_apiproject.sh --api_project "uszip" --build_version "1.0.1" --stagename "qa" --testenvvars "apigateway_baseurl_qa=$APIGW_QA_URL"
```