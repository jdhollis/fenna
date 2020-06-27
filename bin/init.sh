#!/usr/bin/env bash

backend_profile=$(cat .fenna/backend_profile)

if [[ -f ".fenna/suffix" ]]
  terraform init \
    -backend-config .fenna/backend \
    -backend-config "profile=${backend_profile}" \
    -backend-config "key=$(cat .fenna/service_name)-$(cat .fenna/suffix)/terraform.tfstate" \
    ${1-}
then
else
  terraform init \
    -backend-config .fenna/backend \
    -backend-config "profile=${backend_profile}" \
    ${1-}
fi
