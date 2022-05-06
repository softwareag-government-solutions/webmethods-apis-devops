#!/bin/bash
##############################################################################
##
## This script can be used for developers import and export APIs(projects) 
## as a flat file representation of the VCS.
## Parameters: 
## import(or)export           To import or export from the flat file.
## api_project	                  The API project to import.
## apigateway_url		      APIGateway url to import or export from.Default is http://localhost:5555.
## apigateway_es_port		  API Gateway Elastic search port.Default is 9240
## username                   The APIGateway username.Default is Administrator.
## password				      The APIGateway password.Default is password.
## 
##############################################################################
. ./common.sh
CURR_DIR="$PWD"
url=http://localhost:5555
username=Administrator
password=manage
apiproject=
shldDoImport=
#Usage of this script
usage(){
echo "Usage: $0 args"
echo "args:"
echo "--import(or)--export  *To import or export from the flat file"
echo "--api_project		      *The API project to import"
echo "--apigateway_url      APIGateway url to import or export from.Default is http://localhost:5555"
echo "--username            The APIGateway username.Default is Administrator."
echo "--password            The APIGateway password.Default is password."
exit
}

#Parseinputarguments
parseArgs(){
  while test $# -ge 1; do
    arg=$1
    shift
    case $arg in
      --apigateway_url)
        url=${1}
        shift
      ;;
      --api_project)
        apiproject=${1}
        shift
      ;;
      --username)
        username=${1}
        shift
      ;;      
      --password)
        password=${1}
        shift
	  ;;	
	  --import)
        shldDoImport='true'
      ;;
	  --export)
        shldDoImport='false'
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
if [ -z "$apiproject" ] 
then 
	echo "API project name is missing" 
usage
fi
if [ -z "$shldDoImport" ] 
then 
	echo "Missing what operation to do" 
usage
fi

if [ "$shldDoImport" = "true" ]
then
    echo "Importing the API project"
	import_api $apiproject $url $username $password
else
	export_api $apiproject $url $username $password
fi
}


#Call the main function with all arguments passed in...
main "$@"