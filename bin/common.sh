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
JQ_EXE="jq"

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
		exit 10;
	fi
	cd $BIN_DIR
}

##############################################################################
## Import an API to the API Gateway Server.
## Usage: deploy_api <api_project> <stagename> <deploy_apigateway_url> <deploy_username> <deploy_password>
##############################################################################
deploy_apiproject() {
	apiproject_dir="$1"
	stagename="$2"

	url="$3"
	username="$4"
	password="$5"
	
	## first let's get the api build from the repo
	if [ ! -d "$apiproject_dir" ]; then
		echo "ERROR: $apiproject_dir does not exist...exit"
		exit 10;
	fi

	## first let's stage the api
	preps_stage_apiproject $apiproject_dir $stagename

	## get staging dir
	STAGING_PREPS_DIR=$(staging_preps_dir $apiproject_dir $stagename)
	API_ASSETS_DIR="$STAGING_PREPS_DIR/assets"

	if [ -d "$API_ASSETS_DIR" ] 
	then
		cd $API_ASSETS_DIR && zip -r $BASEDIR/$api_project.zip ./*
		curl -sS -i -X POST "$url/rest/apigateway/archive?preserveAssetState=true&overwrite=*" -H "Content-Type:application/zip" -H"Accept:application/json" --data-binary @"$BASEDIR/$api_project.zip" -u $username:$password > /dev/null
		rm $BASEDIR/$api_project.zip
	else
		echo "The staged API assets for $API_ASSETS_DIR do not exist..."
		exit 10;
	fi
}

##############################################################################
## Staging prep dir
## Usage: staging_preps_dir <api_project_dir> <stagename>
##############################################################################
staging_preps_dir() {
	api_project_dir=$1
	stagename=$2
	echo $BASEDIR/tmp/deploy_preps/$(basename $api_project_dir)/$stagename
}

##############################################################################
## Stage an API 
## Usage: preps_stage_apiproject <api_project> <stagename>
##############################################################################
preps_stage_apiproject() {
	api_project_dir=$1
	stagename=$2

	## first let's get the api build from the repo
	if [ ! -d "$api_project_dir" ]; then
		echo "ERROR: $api_project_dir does not exist...exit"
		exit 10;
	fi

	STAGING_PREPS_DIR=$(staging_preps_dir $api_project_dir $stagename)
	API_ALIASES_DIR=$STAGING_PREPS_DIR/assets/Alias
	API_ACDL_FILE=assets/APIGatewayAssets.acdl

	if [ -d "$STAGING_PREPS_DIR" ]; then
		rm -Rf $STAGING_PREPS_DIR
	fi
	mkdir -p $STAGING_PREPS_DIR
	cp -r $api_project_dir/* $STAGING_PREPS_DIR/

	## check if aliases file is defined
	if [ -d "$API_ALIASES_DIR" ] ; then
		if [ -f "$STAGING_PREPS_DIR/aliases.json" ] ; then
			echo "Parsing the Alias files in $API_ALIASES_DIR"
			for file in $API_ALIASES_DIR/*; do
				filename=$(basename $file)
				echo filename: $filename
		
				aliasId="${filename#*.}"
				echo aliasId: $aliasId

				## first, let's check if alias exists...if not, let's fail??
				newAliasEnv=$($JQ_EXE -c --arg id "$aliasId" '.[] | select( .id==$id ) | .'$stagename $STAGING_PREPS_DIR/aliases.json)
				if [ "$newAliasEnv" != "null" ] ; then
					echo "Executing: $JQ_EXE -c --arg id "$aliasId" '.[] | select( .id==\$id ) | .'$stagename' + { id : \$id }' $STAGING_PREPS_DIR/aliases.json"
					newAlias=$($JQ_EXE -c --arg id "$aliasId" '.[] | select( .id==$id ) | .'$stagename' + { id : $id }' $STAGING_PREPS_DIR/aliases.json)
					echo "got new alias=$newAlias"
					echo $newAlias > $file.new
					cat $file $file.new | $JQ_EXE -s add > $file
					rm -f $file.new
				else
					echo "No matching alias id $aliasId for stagename $stagename...Not doing any alias replacement and ignoring!"
				fi
			done
		else
			echo "No stagename-aliases file found in $STAGING_PREPS_DIR/aliases.json...Not doing any alias replacement and ignoring!"
		fi

		## final cleanup of the ACDL file for the alias properties
		## TODO: this is not ideal...defintely would be best using XML parser or other technique...
		if [ -f $api_project_dir/$API_ACDL_FILE ] ; then
			sed 's/<property/<!-- <property/gI; s/<\/property>/<\/property> -->/gI' "$api_project_dir/$API_ACDL_FILE" > $STAGING_PREPS_DIR/$API_ACDL_FILE
		fi
	else
		echo "No aliases found in $STAGING_PREPS_DIR"
	fi
}

##############################################################################
## Import an API to the API Gateway Server.
## Usage: deploy_api <api_project> <environment> <deploy_apigateway_url> <deploy_username> <deploy_password>
##############################################################################
package_apiproject() {
	api_project="$1"
	build_version="$2"
	stage_dir="$3"
	create_stage_dir="$4"

	BIN_DIR="$THISDIR"
	API_DIR=$BASEDIR/apis/$api_project
	
	if [ "x$stage_dir" == "x" ]; then
		echo "ERROR: $stage_dir i snot specified...exit"
		exit 10;
	fi

	if [ "$create_stage_dir" == "true" ]; then
		mkdir -p $stage_dir
	fi

	if [ ! -d "$stage_dir" ]; then
		echo "ERROR: $stage_dir does not exist...exit"
		exit 10;
	fi
		
	if [ -d "$API_DIR" ] 
	then
		cd $API_DIR && zip -r $BASEDIR/$api_project-$build_version.zip ./*
		
		## copy to stage_dir
		cp -f $BASEDIR/$api_project-$build_version.zip $stage_dir/

		rm $BASEDIR/$api_project-$build_version.zip
	else
		echo "The API assets with name $api do not exist as a flat file."
		exit 10;
	fi
	cd $BIN_DIR
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
		exit 10;
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
		exit 10;
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
		exit 10;
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
		newman_environment="$newman_environment --env-var $i"
	done
 fi

 echo "Running postman tests with environments:"
 echo "- Environment File: $ENVFILE"
 echo "- Environment vars: $newman_environment"
 
 newman run $test_collection --reporters cli,junit,html --reporter-junit-export $result_folder/$RANDOM.xml -e $environment_file $newman_environment --reporter-html-export $result_folder/index.html
}

############################################################################################################################################################
## Run the entire postman test suite pointing to an API Gateway server.
## 
## When 'all' is passed all tests under tests/test-suites are run
## Usage run_test_suite <test_suite> <environment_file_location> <api_gateway_server> <test_result_folder>
############################################################################################################################################################
run_test_suite() {
	apiproject_dir="$1"
	stagename="$2"
    test_suite="$3"
	env_vars="$4"

	ENVFILE_DIR=$BASEDIR/environments
	ENVFILE=$ENVFILE_DIR/${environment}_environment.json

	API_DIR=
	if [ "$build_version" != "local" ]; then
		API_DIR=$BASEDIR/apis/$api_project
	else
		API_DIR=$(staging_builds_dir $api_project $build_version)
	fi

 	RESULT_FOLDER=$BASEDIR/testresults/$(basename $API_DIR)

	if [ -d "$RESULT_FOLDER" ] 
	then
		rm -R $RESULT_FOLDER
	fi
	mkdir $RESULT_FOLDER
 
	if [ -d "$API_DIR" ]; then
		echo "Running tests for API project $API_DIR"
		if [ -d "$API_DIR/tests" ]; then
			if [ "$test_suite" = "all" ]; then 
				echo "Running ALL tests in $API_DIR/tests"
				for file in $API_DIR/tests/*; do
					run_test $file $ENVFILE "$RESULT_FOLDER" "$env_vars"
				done
			else
				if [ -f "$API_DIR/tests/$test_suite" ]; then
					run_test $API_DIR/tests/$test_suite $ENVFILE "$RESULT_FOLDER" "$env_vars"
				else
					echo "The API test suite with name $API_DIR/tests/$test_suite does not exists"
					exit 10;
				fi
			fi
		fi
	else
		echo "The API project with name $API_DIR does not exists"
		exit 10;
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

