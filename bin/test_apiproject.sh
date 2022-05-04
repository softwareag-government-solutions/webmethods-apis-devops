#!/bin/bash

. ./common.sh

## variables
api_project_basedir=$BASEDIR/apis
api_package_extract_basedir=$BASEDIR/tmp

api_project=
api_project_package=
stagename=
testsuite=
testenvvars=

#Usage of this script
usage(){
  echo "Usage: $0 args"
  echo "args:"
  echo "--api_project		           The API project to import (as defined in $BASEDIR/apis)"
  echo "--api_project_package      A zip file of the api project - if specified, api_project"
  echo "--stagename                The stagename level"
  echo "--testsuite           The test suite to run. If not specified, all tests will be run."
  echo "--testenvvars         Some extra env vars to pass for the test, semi-colon separated"
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
      --api_project_package)
        api_project_package=${1}
        shift
      ;;  
      --stagename)
        stagename=${1}
        shift
	    ;;
      --testsuite)
        testsuite=${1}
        shift
      ;;
      --testenvvars)
        testenvvars=${1}
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

  if [ -z "$stagename" ] 
  then 
    echo "stagename is missing" 
    usage
  fi

  if [ -z "$testsuite" ] 
  then 
    testsuite="all"
  fi

  if [[ -z "$api_project" && -z $api_project_package ]] 
  then 
    echo "One of required 'API project name' or 'API project package' is missing..." 
    usage
  fi

  # set the path to the api project
  if [ "x$api_project" != "x" ]; then
    api_project_dir="$api_project_basedir/$api_project"
  fi

  # if package path if provided, then potentially overwrite the path to the project
	if [ -f "$api_project_package" ]; then
    extract_dir="$api_package_extract_basedir/$(basename $api_project_package)/"
    
    # clear extract dir if if was already there
    if [ -d "$extract_dir" ]; then
      rm -Rf $extract_dir
    fi
    mkdir -p $extract_dir
    
    # unzip package
    unzip -o $api_project_package -d $extract_dir/

    # set new deploy dir
    api_project_dir=$extract_dir
  fi

  run_test_suite "$api_project_dir" "$stagename" "$testsuite" "$testenvvars"
}

#Call the main function with all arguments passed in...
main "$@"