#!/bin/bash

. ./common.sh

## variables
api_project=
build_version=
environment=
testsuite=
testenvvars=

#Usage of this script
usage(){
  echo "Usage: $0 args"
  echo "args:"
  echo "--api_project		      *The API project to import"
  echo "--build_version       the revision for the build"
  echo "--environment         The environment level"
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
      --build_version)
        build_version=${1}
        shift
      ;;    
      --environment)
        environment=${1}
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

  if [ -z "$api_project" ] 
  then 
    echo "API project name is missing" 
  usage
  fi

  if [ -z "$build_version" ] 
  then 
    echo "Build version is missing" 
  usage
  fi

  if [ -z "$environment" ] 
  then 
    echo "environment is missing" 
  usage
  fi

  if [ -z "$testsuite" ] 
  then 
    testsuite="all"
  fi

  run_test_suite "$api_project" "$build_version" "$testsuite" "$environment" "$testenvvars"
}

#Call the main function with all arguments passed in...
main "$@"