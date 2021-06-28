#!/usr/bin/env bash
set -e
nextflow run gwas-regenie.nf
nextflow run gwas-regenie.nf -c tests/test-gwas-binary.conf
nextflow run gwas-regenie.nf -c tests/test-gwas-vcf.conf
nextflow run gwas-regenie.nf -c tests/test-gwas-header.conf
