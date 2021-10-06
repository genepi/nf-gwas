#!/bin/bash
set -e


# test all config files in tests folder
config_files="tests/*.conf"
for config_file in $config_files
do
  echo "---------------------------------------------------------"
  echo "Execute Test $config_file..."
  echo "---------------------------------------------------------"
  nextflow run main.nf -c $config_file -profile docker -resume
done
