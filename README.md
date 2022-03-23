# webmethods-apis-devops
All the sample apis for softwareag gov solutions + a good devops sample for apis

## Secrets

```bash
export APIGW_DEV_URL="http://172.28.4.101:5555"
export APIGW_DEV_DEPLOY_USER="Administrator"
echo -n "DEV ENV Administrator password: "; read -s password; export APIGW_DEV_DEPLOY_PASSWORD=$password
```

```bash
export APIGW_QA_URL="http://internal-repro1011-reproalb-1378200756.us-east-1.elb.amazonaws.com"
export APIGW_QA_DEPLOY_USER="Administrator"
echo -n "QA ENV Administrator password: "; read -s password; export APIGW_QA_DEPLOY_PASSWORD=$password
```

## Development (usually on your local or a dev server)

### Raw import the apis from git, as-is (no staging)

```bash
./gateway_import_export_utils.sh --import --api_name bookstore --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --import --api_name bookstore --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --import --api_name covid --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --import --api_name uszip --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --import --api_name sagtours --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD
```

### export the apis to save in git once work is done

```bash
./gateway_import_export_utils.sh --export --api_name bookstore --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --export --api_name covid --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --export --api_name uszip --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD

./gateway_import_export_utils.sh --export --api_name sagtours --apigateway_url $APIGW_DEV_URL --username $APIGW_DEV_DEPLOY_USER --password $APIGW_DEV_DEPLOY_PASSWORD
```

## Deploy 

These should usually be automated using a build pipeline tool like Jenkins...

## deploy environment-staged apis

```bash
source common.lib; deploy_staged_api "bookstore" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
source common.lib; deploy_staged_api "covid" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
source common.lib; deploy_staged_api "uszip" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
source common.lib; deploy_staged_api "sagtours" "qa" "$APIGW_QA_URL" "$APIGW_QA_DEPLOY_USER" "$APIGW_QA_DEPLOY_PASSWORD"
```

### run tests

```bash
source common.lib; run_test_suite "bookstore" "all" "qa_environment.json"
source common.lib; run_test_suite "covid" "all" "qa_environment.json"
source common.lib; run_test_suite "uszip" "all" "qa_environment.json"
```