# GWAS-Regenie

[![GWAS_Regenie](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml)

A nextflow pipeline to perform whole genome regression modelling using Regenie.

## Requirements

- Nextflow:

```
curl -s https://get.nextflow.io | bash
```

## Run test pipeline

```
github pull https://github.com/genepi/gwas-regenie/
nextflow run gwas-regenie.nf -profile test,docker -c conf/test.config
```

## Run pipeline
```
nextflow run -c <config> genepi/gwas-regenie -r v0.1.2
```

## Parameters

### Required parameters


| Option        |Description          | Value  |
| ------------- |-----------------| -------------| 
| `project`     | my-gwas | Project name | 
| `genotypes_typed`     |  /path/to/allChrs.{bim,bed,fam} | Path to the array genotypes (single merged file in plink format).  |
| `genotypes_imputed`     |  /path/to/vcf/\*vcf.gz or /path/to/bgen/\*bgen | Path to imputed genotypes in VCF or BGEN format) |
| `genotypes_imputed_format `     | vcf *or* bgen | Input file format of imputed genotypes   | 
| `build`     | hg19 *or* hg38 | Imputed genotypes build format | 
| `phenotypes_filename `     | /path/to/phenotype.txt | Path to phenotype file | 
| `phenotypes_columns`     | 'phenoColumn1,phenoColumn2,phenoColumn3' | List of phenotypes | 
| `phenotypes_binary_trait`     | false, true | Binary trait? | 
| `regenie_test_model`     | additive, recessive *or* dominant |  Define test | 

### Addtional phenotype parameters

| Option        |Description          | Default |
| ------------- |-----------------| -------------| 
| `date`     | Date of today | Project data |  
| `outdir`     | "results/${params.project}" | Output directory   
| `covariates_filename`     |  empty | Specify covariates file | 
| `covariates_columns`     | empty | List of covariates |  
| `phenotypes_delete_missings`     | false | Removing samples with missing data at any of the phenotypes | 
| `prune_enabled`     | prune_enabled | Used threads | 
| `prune_maf`     | 0.01 | MAF filter | 
| `prune_window_kbsize`     |  50 | Used threads |
| `prune_step_size`     |   5 | Step Size |
| `prune_r2_threshold`     |   0.2 | R2 threshold |
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


## Profiles 
By default, the pipeline is executed using Docker. Add ` -profile singularity ` to run it with Singularity. 

## Test Pipeline
Test the pipeline and the created docker image with test-data:

```
git pull https://github.com/genepi/gwas-regenie/
nextflow run gwas-regenie.nf
```
## Pipeline steps

1) Convert imputed data into [pgen](https://github.com/chrchang/plink-ng/blob/master/pgen_spec/pgen_spec.pdf) (VCF only).
2) Prune genotyped data (optional).
3) Filter genotyped data based on MAF, MAC, HWE, genotype missingess and sample missingness. 
4) Run Regenie Step 1 and Step 2
5) Filter by pvalue
6) Annotate top hits
7) Create Rmarkdown report


## Build local image
You can also build the image locally and set it in `ǹextflow.config`

```
docker build -t genepi/gwas-regenie . # don't ingore the dot here
```

## License
gwas-regenie is MIT Licensed.
