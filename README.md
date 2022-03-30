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

## Option 1 - CD only, directly from Git code (without storing in artifact repo)

In this option, we don't store a "build" in an artifact repo...we simply push the artifact in git into the target env...
### deploy

```bash
sh gateway_deploy_fromlocal.sh --api_project "bookstore" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
sh gateway_deploy_fromlocal.sh --api_project "covid" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
sh gateway_deploy_fromlocal.sh --api_project "uszip" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
sh gateway_deploy_fromlocal.sh --api_project "sagtours" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
```

##  Option 2 - CI/CD (with storing in artifact repo)

In this option, we store a "build" in an artifact repo...
And then, in a deploy stage, we push the build artifact to the target env...

### CI + storing in artifact repo

Build a package for an api project with the build number, and push it to a central artifact repo location (here a local folder, but could be nexus or other)

```bash
sh gateway_package_build.sh --api_project "bookstore" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo"
sh gateway_package_build.sh --api_project "covid" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo"
sh gateway_package_build.sh --api_project "uszip" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo"
sh gateway_package_build.sh --api_project "sagtours" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo"
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
sh gateway_deploy_build.sh --api_project "bookstore" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD

sh gateway_deploy_build.sh --api_project "covid" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD

sh gateway_deploy_build.sh --api_project "uszip" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD

sh gateway_deploy_build.sh --api_project "sagtours" --build_version "1.0.1" --repodir "$HOME/apigatewaycirepo" --environment "qa" --apigateway_url $APIGW_QA_URL --username $APIGW_QA_DEPLOY_USER --password $APIGW_QA_DEPLOY_PASSWORD
```

## run tests

```bash
sh gateway_test_build.sh --api_project "bookstore" --build_version "1.0.1" --environment "qa" --testenvvars "apigateway_baseurl_qa=$APIGW_QA_URL"
sh gateway_test_build.sh --api_project "covid" --build_version "1.0.1" --environment "qa" --testenvvars "apigateway_baseurl_qa=$APIGW_QA_URL"
sh gateway_test_build.sh --api_project "uszip" --build_version "1.0.1" --environment "qa" --testenvvars "apigateway_baseurl_qa=$APIGW_QA_URL"
```