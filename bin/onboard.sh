#!/usr/bin/env bash

echo "What AWS profile would you like to use as your root profile?"
  read -p "> " root_profile
echo

echo $root_profile > .fenna/root_profile

backend_env=$(cat .fenna/backend/env)

if [[ $backend_env == "root" ]]
then
  backend_profile=$root_profile
else
  backend_profile="${root_profile}-${backend_env}"
fi

echo $backend_profile > .fenna/backend/profile

if [[ -f ".fenna/sandbox" ]]
then
  sandbox_env=$(cat .fenna/sandbox)
  profile=${root_profile}-${sandbox_env}

  echo "What suffix would you like to use to distinguish your resources in the sandbox?"
    read -p "> " suffix
  echo

  echo $suffix > .fenna/suffix
  touch user.tfvars
  touch ${sandbox}.tfvars
else
  target_env=$(readlink .fenna/backend/current | sed -e 's/\.fenna\/backends\/\(.*\)\.tfvars/\1/')

  if [[ $target_env == "root" ]]
  then
    profile=$root_profile
  else
    profile=${root_profile}-${target_env}
  fi
fi

echo $profile > .fenna/profile
