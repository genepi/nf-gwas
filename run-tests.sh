#!/bin/bash
set -e

# default test to check dependencies
nextflow run gwas-regenie.nf

# test all config files in tests folder
config_files="tests/*.conf"
for config_file in $config_files
do
  echo "---------------------------------------------------------"
  echo "Execute Test $config_file..."
  echo "---------------------------------------------------------"
  nextflow run gwas-regenie.nf -c $config_file
done
