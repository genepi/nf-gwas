# GWAS-Regenie

[![GWAS_Regenie](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml)

A nextflow pipeline to perform whole genome regression modelling using Regenie.

## Requirements

- Nextflow:

```
curl -s https://get.nextflow.io | bash
```

## Run
 
```
nextflow run -c <config> genepi/gwas-regenie -r v0.1.3 -profile [docker,singularity]
```

## Profiles 
You can run the pipeline using Docker or Singularity. Add ` -profile singularity ` to run it with Singularity. 

## Build and run locally

```
github pull https://github.com/genepi/gwas-regenie/
docker build -t genepi/gwas-regenie .
nextflow run gwas-regenie.nf -profile test,docker -c conf/test.config
```

## Parameters
Pleas click [here](tests) for different config files. 

### Required parameters


| Option        | Value          | Description  |
| ------------- |-----------------| -------------| 
| `project`     | my-project-name | Name of the project | 
| `genotypes_typed`     |  /path/to/allChrs.{bim,bed,fam} | Path to the array genotypes (single merged file in plink format).  |
| `genotypes_imputed`     |  /path/to/vcf/\*vcf.gz or /path/to/bgen/\*bgen | Path to imputed genotypes in VCF or BGEN format) |
| `genotypes_imputed_format `     | vcf *or* bgen | Input file format of imputed genotypes   | 
| `genotypes_build`     | hg19 *or* hg38 | Imputed genotypes build format | 
| `phenotypes_filename `     | /path/to/phenotype.txt | Path to phenotype file | 
| `phenotypes_columns`     | 'phenoColumn1,phenoColumn2,phenoColumn3' | List of phenotypes | 
| `phenotypes_binary_trait`     | false, true | Binary trait? | 
| `regenie_test`     | additive, recessive *or* dominant |  Define test | 

### Optional parameters

| Option        |Default          | Description |
| ------------- |-----------------| -------------| 
| `date`     | today | Date in report |  
| `outdir`     | "results/${params.project}" | Output directory   
| `covariates_filename`     |  empty | path to covariates file | 
| `covariates_columns`     | empty | List of covariates |  
| `phenotypes_delete_missings`     | false | Removing samples with missing data at any of the phenotypes | 
| `prune_enabled`     | false | Enable pruning step | 
| `prune_maf`     | 0.01 | MAF filter | 
| `prune_window_kbsize`     |  50 | Window size |
| `prune_step_size`     |   5 | Step size (variant ct) |
| `prune_r2_threshold`     |   0.2 | Unphased hardcall R2 threshold|
| `qc_maf`     |   0.01 | Minor allele frequency (MAF) filter | 
| `qc_mac`     |  100 | Minor allele count (MAC) filter |  
| `qc_geno`     | 0.1 | Genotype missingess |  
| `qc_hwe`     | 1e-15 | Hardy-Weinberg equilibrium (HWE) filter |  
| `qc_mind`     | 0.1 | Sample missigness |  
| `regenie_bsize_step1`     | 1000 | Size of the genotype blocks |  
| `regenie_bsize_step2`     | 400 | Size of the genotype blocks |  
| `regenie_sample_file`     |  empty | Sample file corresponding to input BGEN file | 
| `regenie_skip_predictions`     | false | Skip Regenie Step 1 predictions |  
| `regenie_min_imputation_score`     |  0.00 | Minimum imputation info score (IMPUTE/MACH R^2)  | 
| `regenie_min_mac`     |  5 | Minimum minor allele count  | 
| `regenie_range`     |  '' [format=CHR:MINPOS-MAXPOS] | Apply Regenie only on specify region | 
| `min_pvalue`     |   2 | Filter results with logp10 < 2 |
| `tophits`     |   50 | # of tophits (sorted by pvalue) with annotation |


## Pipeline steps

1) Convert imputed data into [pgen](https://github.com/chrchang/plink-ng/blob/master/pgen_spec/pgen_spec.pdf) (VCF only).
2) Prune genotyped data (optional).
3) Filter genotyped data based on MAF, MAC, HWE, genotype missingess and sample missingness. 
4) Run Regenie Step 1 and Step 2
5) Filter by pvalue
6) Annotate top hits
7) Create Rmarkdown report

## License
gwas-regenie is MIT Licensed.
