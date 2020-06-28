#!/usr/bin/env bash

if [[ ! -d ".fenna" ]]
then
	mkdir -p .fenna/backend
fi

cat > .fenna/.gitignore <<EOS
backend/profile
root_profile
suffix
EOS

echo "What is this service named?"
  read -p "> " service_name
echo

echo $service_name > .fenna/service_name

# echo "What's your backend config repository's URL?"
# read repository_url
# git submodule add $repository_url .fenna/backends

echo "Will this service be developed in a sandbox? [yes no]"
  read -p "> " is_sandboxable
echo

environments=$(ls -1 .fenna/backends | sed -e 's/\.tfvars$//')

if [[ $is_sandboxable == "yes" ]]
then
  echo "What is the sandbox environment named? [$(echo $environments)]"
    read -p "> " sandbox_env
  echo

  backend=$sandbox_env
  echo $sandbox_env > .fenna/sandbox
else
  echo "Which backend would you like to use? [$(echo $environments)]"
    read -p "> " backend
  echo
fi

ln -sf ".fenna/backends/${backend}.tfvars" .fenna/backend/current

echo "Where is your backend stored? [$(echo $environments)]"
  read -p "> " backend_env
echo

echo $backend_env > .fenna/backend/env

echo "user.tfvars" >> .gitignore

# fenna onboard
