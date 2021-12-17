---
layout: page
title: "Configuration"
nav_order: 5
---

## Configuration

Before running GWAS-Regenie, [pipeline parameters](params/params) must be specified **and** the cpus/memory directives set in the Nextflow configuration file with `-c gwas.config`. Learn about Nextflow configuration files [here](https://www.nextflow.io/docs/latest/config.html) or read our [Beginners Guide](gwas-regenie-101/beginners-guide).

### Setting Parameters

The GWAS-Regenie pipeline currently supports imputed files in **BGEN** or **VCF** format (coming from [Michigan Imputation Server](https://imputationserver.sph.umich.edu/)). For genotyped data, only plink format is currently supported.

####  BGEN files
Below please find a GWAS configuration for UK Biobank.

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
Below please find a GWAS configuration for VCF data.

```
params {
  project                       = 'mis-gwas'
  genotypes_array               = '/data/genotyped/gckd_cal_allChrs.{bim,bed,fam}'
  genotypes_imputed             = '/data/imputed/vcf-format/vcfs/*vcf.gz'
  genotypes_build               = 'hg19'
  genotypes_imputed_format      = 'vcf'
  phenotypes_filename           = 'phenotype/my_phenotypes.txt'
  phenotypes_columns            = 'phenotype1, phenotype2'
  phenotypes_binary_trait       = false
  regenie_test                  = 'additive'
  prune_enabled                 = true

}
```

### Setting Memory and CPU directives
Depending on your actual server or cluster, the memory and CPU directives must be adapted to run regenie an all required as efficient as possible. Please find below the default setting. Copy/paste the process section to your configuration file and run your GWAS. Fully working examples including different parameters can be found [here](https://github.com/genepi/gwas-regenie/tree/main/conf/tests). We will also adapt this section with memory settings from real-world experiments. Read also [here](https://rgcgithub.github.io/regenie/performance/) to increase the memory for regenie.
```
process {

    withLabel: 'process_plink2' {
        cpus   =  4
        memory =  6.GB
    }

    withLabel: 'required_memory_report' {
        memory =  6.GB
    }

    //recommend to run regenie using multi-threading (8+ threads)
    withName: 'REGENIE_STEP1|REGENIE_STEP2'
    {
        cpus   = 8
        memory = 8.GB
    }

}
```
