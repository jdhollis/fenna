#!/usr/bin/env bash

if [[ ! -d ".fenna" ]]
then
	mkdir .fenna
fi

cat > .fenna/.gitignore <<EOS
backend_profile
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

backends=$(ls -1 .fenna/backends | sed -e 's/\.tfvars$//')

if [[ $is_sandboxable == "yes" ]]
then
  echo "What is the sandbox environment named? [$(echo $backends)]"
    read -p "> " sandbox_env
  echo

  backend=$sandbox_env
  echo $sandbox_env > .fenna/sandbox
  echo "user.tfvars" >> .gitignore
else
  echo "Which backend would you like to use? [$(echo $backends)]"
    read -p "> " backend
  echo
fi

ln -sf ".fenna/backends/${backend}.tfvars" .fenna/backend

# fenna onboard
