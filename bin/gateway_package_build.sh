#!/bin/bash

. ./common.sh

## variables
api_project=
build_version=
repodir=

#Usage of this script
usage(){
  echo "Usage: $0 args"
  echo "args:"
  echo "--api_project		     *The API project to import"
  echo "--build_version      the revision for the build"
  echo "--repodir            The repo directory to put the new build"
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
      --repodir)
        repodir=${1}
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

  if [ -z "$repodir" ] 
  then 
    echo "repodir is missing" 
  usage
  fi

  package_api_build $api_project $build_version $repodir
}

#Call the main function with all arguments passed in...
main "$@"