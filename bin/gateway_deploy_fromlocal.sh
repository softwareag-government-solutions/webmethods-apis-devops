#!/bin/bash

. ./common.sh

## variables
api_project=
environment=
apigwurl=
apigwusername=
apigwpassword=

#Usage of this script
usage(){
  echo "Usage: $0 args"
  echo "args:"
  echo "--api_project		      *The API project to import"
  echo "--environment         The environment level"
  echo "--apigateway_url      APIGateway url to import or export from.Default is http://localhost:5555"
  echo "--username            The APIGateway username."
  echo "--password            The APIGateway password."
  exit
}

#Parseinputarguments
parseArgs(){
  while test $# -ge 1; do
    arg=$1
    shift
    case $arg in
      --api_project)
        api_project=${1}
        shift
      ;;   
      --environment)
        environment=${1}
        shift
	    ;;
      --apigateway_url)
        apigwurl=${1}
        shift
      ;;
      --username)
        apigwusername=${1}
        shift
      ;;      
      --password)
        apigwpassword=${1}
        shift
	    ;;	
      -h|--help)
        usage
      ;;
      *)
        echo "Unknown: $@"
        usage
        exit
      ;;
    esac
  done
}

main(){
  #Parseinputarguments
  parseArgs "$@"

  if [ -z "$api_project" ] 
  then 
    echo "API project name is missing" 
  usage
  fi

  if [ -z "$environment" ] 
  then 
    echo "environment is missing" 
  usage
  fi

  if [ -z "$apigwurl" ] 
  then 
    echo "apigwurl is missing" 
  usage
  fi

  if [ -z "$apigwusername" ] 
  then 
    echo "apigwusername is missing" 
  usage
  fi

  if [ -z "$apigwpassword" ] 
  then 
    echo "apigwpassword is missing" 
  usage
  fi

  deploy_api_fromlocal "$api_project" "$environment" "$apigwurl" "$apigwusername" "$apigwpassword"
}

#Call the main function with all arguments passed in...
main "$@"