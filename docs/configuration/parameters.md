---
layout: page
title: Parameters
parent: Configuration
nav_order: 1
---

## Parameters

The GWAS-Regenie pipeline currently supports imputed files in **BGEN** or **VCF** format (coming from [Michigan Imputation Server](https://imputationserver.sph.umich.edu/)). Please find below to working config files to run GWAS-Regenie.

####  BGEN files
The following minimal configuration file runs an additive model using the UK Biobank data. Click [here](params/params) to see all available pipeline parameters.

```
params {
  project                       = 'ukb-gwas'
  genotypes_array               = '/data/genotyped/ukb_cal_allChrs.{bim,bed,fam}'
  genotypes_imputed             = '/data/imputed/*bgen'
  genotypes_build               = 'hg19'
  genotypes_imputed_format      = 'bgen'
  phenotypes_filename           = 'phenotype/my_phenotypes.txt'
  phenotypes_columns            = 'phenotype1,phenotype2'
  phenotypes_binary_trait       = false
  regenie_test                  = 'additive'
  regenie_sample_file           = 'ukbXXX.sample'
  covariates_filename           = 'phenotype/my_covariates.txt'
  covariates_columns            = 'f.31.0.0,f.21022.0.0,f.22000.0.0,f.22009.0.1,f.22009.0.2'
}
```

####  VCF files
The following minimal configuration file runs an additive model using VCF data from e.g. Michigan Imputation Server. Click [here](./params/params) to see all available pipeline parameters.

```
params {
  project                       = 'mis-gwas'
  genotypes_array               = '/data/genotyped/allChrs.{bim,bed,fam}'
  genotypes_imputed             = '/data/imputed/vcfs/*vcf.gz'
  genotypes_build               = 'hg19'
  genotypes_imputed_format      = 'vcf'
  phenotypes_filename           = 'phenotype/my_phenotypes.txt'
  phenotypes_columns            = 'phenotype1, phenotype2'
  phenotypes_binary_trait       = false
  regenie_test                  = 'additive'
  prune_enabled                 = true

}
```
