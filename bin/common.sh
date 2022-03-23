#!/bin/bash

##############################################################################
##
## This contains the important Library bash functions that are needed for 
## APIGateway CI/CD process.
## All Library methods in this file use the current directory i.e binary
## as the root directory.
## 
##############################################################################

THIS=`basename $0`
THISDIR=`dirname $0`; THISDIR=`cd $THISDIR;pwd`
BASEDIR="$THISDIR/.."
JQ_EXE="$THISDIR/tools/jq"

##############################################################################
##
## Ping an API Gateway Server.
## This checks for the liveliness of the apigateway server 
## by pinging it for a fixed number of iterations.
## The pause time interval for every ping is
## also configurable.
## 
## Usage: ping_apigateway_server <SERVER_URL> <PAUSE_INTERVAL> <ITERATION_COUNT>
##############################################################################
ping_apigateway_server() {

	SERVER=$1
	PAUSE=$2
	ITERATIONS=$3
	HEALTH_URL=rest/apigateway/health

	while true 
	do
		if [ $ITERATIONS -eq 0 ]
		then
			return 0
		fi
		curl -sSf $SERVER/$HEALTH_URL > /dev/null 2>&1
		CS=$?
		if [ $CS -ne 0 ]
		then
			echo "$SERVER is down"
			((ITERATIONS=ITERATIONS-1))
		elif [ $CS -eq 0 ]
		then
			return 1
		fi
		sleep $PAUSE
	done
}

##############################################################################
## Import an API to the API Gateway Server.
## Usage: import_api <api_project> <url> <username> <password>
##############################################################################
import_api() {

	api_project=$1
	url=$2
	username=$3
	password=$4
	BIN_DIR="$THISDIR"
	API_DIR=$BASEDIR/apis/$api_project
	
	if [ -d "$API_DIR/assets" ] 
	then
		cd $API_DIR/assets && zip -r $BASEDIR/$api_project.zip ./*
		curl -sS -i -X POST $url/rest/apigateway/archive?overwrite=* -H "Content-Type:application/zip" -H"Accept:application/json" --data-binary @"$BASEDIR/$api_project.zip" -u $username:$password > /dev/null
		rm $BASEDIR/$api_project.zip
	else
		echo "The API assets with name $api do not exist as a flat file."
	fi
	cd $BIN_DIR
}

##############################################################################
## Import an API to the API Gateway Server.
## Usage: deploy_staged_api <api_project> <environment> <deploy_apigateway_url> <deploy_username> <deploy_password>
##############################################################################
deploy_staged_api() {
	api_project="$1"
	environment="$2"
	url="$3"
	username="$4"
	password="$5"
	
	BIN_DIR="$THISDIR"

	## first let's stage the api
	stage_api $api_project $environment

	## get staging dir
	STAGING_DIR=$(staging_dir $api_project $environment)
	API_ASSETS_DIR="$STAGING_DIR/assets"

	if [ -d "$API_ASSETS_DIR" ] 
	then
		cd $API_ASSETS_DIR && zip -r $BASEDIR/$api_project.zip ./*
		curl -sS -i -X POST "$url/rest/apigateway/archive?preserveAssetState=true&overwrite=*" -H "Content-Type:application/zip" -H"Accept:application/json" --data-binary @"$BASEDIR/$api_project.zip" -u $username:$password > /dev/null
		rm $BASEDIR/$api_project.zip
	else
		echo "The staged API assets for $API_ASSETS_DIR do not exist..."
	fi
	cd $BIN_DIR
}

##############################################################################
## Stage an API 
## Usage: stage_api <api_project> <environment>
##############################################################################
staging_dir() {
	api_project=$1
	environment=$2
	echo $BASEDIR/staging/$api_project/$environment
}

##############################################################################
## Stage an API 
## Usage: stage_api <api_project> <environment>
##############################################################################
stage_api() {
	api_project=$1
	environment=$2 

	BIN_DIR="$THISDIR"
	API_DIR=$BASEDIR/apis/$api_project
	STAGING_DIR=$(staging_dir $api_project $environment)
	API_ALIASES_DIR=$STAGING_DIR/assets/Alias
	API_ACDL_FILE=assets/APIGatewayAssets.acdl
	
	if [ -d "$API_DIR" ]; then
		if [ -d "$STAGING_DIR" ]; then
			rm -Rf $STAGING_DIR
		fi
		mkdir -p $STAGING_DIR
		cp -r $API_DIR/* $STAGING_DIR/

		## check if aliases file is defined
		if [ -d "$API_ALIASES_DIR" ] ; then
			echo "Parsing the Alias files in $API_ALIASES_DIR"
			for file in $API_ALIASES_DIR/*; do
				filename=$(basename $file)
				echo filename: $filename

				aliasId="${filename#*.}"
				echo aliasId: $aliasId

				if [ -f "$STAGING_DIR/aliases.json" ] ; then
					newAlias=$($JQ_EXE -c --arg id "$aliasId" '.[] | select( .id==$id ) | .'$environment' + { id : $id }' $STAGING_DIR/aliases.json)
					echo $newAlias > $file.new
					cat $file $file.new | $JQ_EXE -s add > $file
					rm -f $file.new
				fi
			done

			## final cleanup of the ACDL file for the alias properties
			## TODO: this is not ideal...defintely would be best using XML parser or other technique...
			if [ -f $API_DIR/$API_ACDL_FILE ] ; then
				sed 's/<property/<!-- <property/gI; s/<\/property>/<\/property> -->/gI' "$API_DIR/$API_ACDL_FILE" > $STAGING_DIR/$API_ACDL_FILE
			fi
		else
			echo "No aliases found in $STAGING_DIR"
		fi
	else
		echo "The API project with name $api_project does not exists"
	fi
}

##############################################################################
## Import Configurations to the API Gateway Server.
## Usage: import_configurations <configuration_name> <url> <username> <password>
##############################################################################
import_configurations() {
	configuration_name=$1
	url=$2
	username=$3
	password=$4
	stage=$5
	BIN_DIR="$THISDIR"
	CONF_DIR=$configuration_name
	if [ -d "$CONF_DIR" ] 
	then
		cd $CONF_DIR && zip -r config.zip ./*
		curl -sS -i -X POST $url/rest/apigateway/archive?overwrite=* -H "Content-Type:application/zip" -H"Accept:application/json" --data-binary @"config.zip" -u $username:$password > /dev/null
		rm config.zip
	else
		echo "The Configuration with name $configuration_name does not exists as a flat file."
	fi
	cd $BIN_DIR
}
##############################################################################
## Export an API from the API Gateway Server.
## Usage: export_api <api_project> <url> <username> <password>
##############################################################################
export_api() {
	api_project=$1
	url=$2
	username=$3
	password=$4
	BIN_DIR="$THISDIR"
	API_DIR=$BASEDIR/apis/$api_project
	
	if [ -d "$API_DIR" ]; then
		curl -s $url/rest/apigateway/archive -d @"$API_DIR/export_payload.json" --output $BASEDIR/$api_project.zip -u $username:$password -H "x-HTTP-Method-Override:GET" -H "Content-Type:application/json"
		if [ -d "$API_DIR/assets" ]; then
			rm -Rf $API_DIR/assets
		fi
		mkdir -p $API_DIR/assets
		unzip -o $BASEDIR/$api_project.zip -d $API_DIR/assets
		rm $BASEDIR/$api_project.zip
	else
		echo "The API with name $api does not exists in the flat file."
	fi
}
##############################################################################
## Export an API from the API Gateway Server.
## Usage: export_api <api_project> <url> <username> <password>
##############################################################################
export_configurations() {
	configuration_name=$1
	url=$2
	username=$3
	password=$4
	BIN_DIR="$THISDIR"
	CONF_DIR=$configuration_name
	
	if [ -d "$CONF_DIR" ] 
	then
	curl -s $url/rest/apigateway/archive -d @"$CONF_DIR/export_payload.json" --output config.zip -u $username:$password -H "x-HTTP-Method-Override:GET" -H "Content-Type:application/json"
	unzip -o config.zip -d $CONF_DIR/
	rm config.zip
	else
	echo "The Configuration with name $configuration_name does not exists in the flat file."
	fi
}


############################################################################################################################################################
## Run a single test suite pointing to a postman collection
## This method allows to pass ';' seperated postman environmental variables.
## Usage run_test <collection_name> <environment_file_location> <environment_Variables> <test_result_folder>
############################################################################################################################################################
run_test() {
 test_collection=$1
 environment_file=$2 
 result_folder=$3
 env_vars=$4

 newman_environment=
 if [ ! -z "$env_vars" ]
 then
    split $env_vars ";"
	echo $env_vars_array
	for i in "${env_vars_array[@]}"  
	do  
		newman_environment="$newman_environment --env-var \"$i\" "
	done
 fi

 ENVFILE_DIR=$BASEDIR/environments
 ENVFILE=$ENVFILE_DIR/$environment_file

 echo "Running postman tests with environments:"
 echo "- Environment File: $ENVFILE"
 echo "- Environment vars: $newman_environment"
 
 newman run $test_collection  --reporters cli,junit,html --reporter-junit-export $result_folder/$RANDOM.xml -e $ENVFILE $newman_environment --reporter-html-export $result_folder/index.html
}

############################################################################################################################################################
## Run the entire postman test suite pointing to an API Gateway server.
## 
## When 'all' is passed all tests under tests/test-suites are run
## Usage run_test_suite <test_suite> <environment_file_location> <api_gateway_server> <test_result_folder>
############################################################################################################################################################

run_test_suite() {
	api_project=$1
    test_suite=$2
	environment_file_location=$3

	API_DIR=$BASEDIR/apis/$api_project
 	RESULT_FOLDER=$BASEDIR/testresults/$api_project

	if [ -d "$RESULT_FOLDER" ] 
	then
		rm -R $RESULT_FOLDER
	fi
	mkdir $RESULT_FOLDER
 
	if [ -d "$API_DIR" ]; then
		echo "Running tests for API project $api_project"
		if [ -d "$API_DIR/tests" ]; then
			if [ "$test_suite" = "all" ]; then 
				echo "Running ALL tests in $API_DIR/tests"
				for file in $API_DIR/tests/*; do
					run_test $file $environment_file_location "$RESULT_FOLDER"
				done
			else
				run_test $API_DIR/tests/$test_suite $environment_file_location "$RESULT_FOLDER"
			fi
		fi
	else
		echo "The API project with name $api_project does not exists"
	fi
}

############################################################################################################################################################
## Promotes an API Project using the API Gateway Promotion management API.
## Usage promote_api <api_project> <environment_file_location> <environment_Variables>
############################################################################################################################################################
promote_api() {

   BASEDIR="../"
   PROMOTION_MANAGEMENT=$BASEDIR/utilities/promotion/PromotionManagement.json
   PROMOTION_MANAGEMENT_PAYLOAD=$BASEDIR/apis/$1/promotion_payload.json
   env_vars=$3
   
   newman_environment=
 
	 if [ ! -z "$env_vars" ]
	 then
		split $env_vars ";"
		echo $env_vars_array
		for i in "${env_vars_array[@]}"  
		do  
			newman_environment="$newman_environment --env-var $i "
		done  
	 fi
   
   newman run $PROMOTION_MANAGEMENT  -g $2 -e $PROMOTION_MANAGEMENT_PAYLOAD $newman_environment
}


##############################################################################
## Utility method to split a input with an delimter
## Usage split input delimiter
## Output array of the string that is split.
##############################################################################
split() {
  input=$1
  delimiter=$2
  string=$input$delimiter

#Split the text based on the delimiter
env_vars_array=()
while [[ $string ]]; do
  env_vars_array+=( "${string%%"$delimiter"*}" )
  string=${string#*"$delimiter"}
done
}

