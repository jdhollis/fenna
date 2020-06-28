#!/usr/bin/env bash

profile=$(cat .fenna/profile)

if [[ -f ".fenna/sandbox" ]]
then
  sandbox_env=$(cat .fenna/sandbox)
  suffix=$(cat .fenna/suffix)

  terraform plan \
    -var "profile=${profile}" \
    -var "suffix=${suffix}" \
    -var-file "${sandbox_env}.tfvars"
    -var-file user.tfvars \
    -out plan \
    ${1-}
else
  terraform plan \
    -var "profile=${profile}" \
    -var-file user.tfvars \
    -out plan \
    ${1-}
fi
