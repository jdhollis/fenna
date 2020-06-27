#!/usr/bin/env bash

echo "What AWS profile would you like to use as your root profile?"
  read -p "> " root_profile
echo

echo $root_profile > .fenna/root_profile

backend_env=$(readlink .fenna/backend | sed -e 's/\.fenna\/backends\/\(.*\)\.tfvars/\1/')

if [[ $backend_env == "root" ]]
then
  backend_profile=$root_profile
else
  backend_profile="${root_profile}-${backend_env}"
fi

echo $backend_profile > .fenna/backend_profile

if [[ -f ".fenna/sandbox" ]]
then
  echo "What suffix would you like to use to distinguish your resources in the sandbox?"
    read -p "> " suffix
  echo

  echo $suffix > .fenna/suffix
  touch user.tfvars
  touch $(cat .fenna/sandbox).tfvars
fi
