# GWAS-Regenie

[![GWAS_Regenie](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml)

A nextflow pipeline to perform whole genome regression modelling using Regenie.

## Requirements

- Nextflow:

```
curl -s https://get.nextflow.io | bash
```

## Run Pipeline

```
nextflow run -c <config> genepi/gwas-regenie -r v0.1.2
```

## Parameters

### Required parameters


| Option        |Description          | Value  |
| ------------- |-----------------| -------------| 
| `project`     | Project name | my-gwas | 
| `genotypes_typed`     | Path to the array genotypes (single merged file in plink format).  | /path/to/allChrs.{bim,bed,fam} |
| `genotypes_imputed`     | Path to imputed genotypes in VCF or BGEN format) | /path/to/vcf/\*vcf.gz or /path/to/bgen/\*bgen |
| `genotypes_imputed_format `     | Input file format of imputed genotypes   | vcf *or* bgen |
| `build`     | Imputed genotypes build format | hg19 *or* hg38 |
| `phenotypes_filename `     | Path to phenotype file | /path/to/phenotype.txt |
| `phenotypes_columns`     | List of phenotypes | 'phenoColumn1,phenoColumn2,phenoColumn3' |
| `phenotypes_binary_trait`     | Binary trait? | false, true | 
| `regenie_test_model`     | Define test | additive, recessive *or* dominant | 

### Addtional phenotype parameters

| Option        |Description          | Default |
| ------------- |-----------------| -------------| 
| `date`     | Project data |  Today |
| `outdir`     | Output directory |  "results/${params.project}" |
| `covariates_filename`     | Specify covariates file |  empty |
| `covariates_columns`     | List of covariates |  empty |
| `phenotypes_delete_missings`     | Removing samples with missing data at any of the phenotypes | false |
| `prune_enabled`     | Used threads | prune_enabled |
| `prune_maf`     | MAF filter | 0.01 |
| `prune_window_kbsize`     | Used threads |  50 |
| `prune_step_size`     | Step Size |  5 |
| `prune_r2_threshold`     | R2 threshold |  0.2 |
| `qc_maf`     |  Minor allele frequency (MAF) filter |  0.01 |
| `qc_mac`     |  Minor allele count (MAC) filter |  100 |
| `qc_geno`     | Genotype missingess |  0.1 |
| `qc_hwe`     | Hardy-Weinberg equilibrium (HWE) filter |  1e-15 |
| `qc_mind`     | Sample missigness |  0.1 |
| `regenie_bsize_step1`     | Size of the genotype blocks |  1000 |
| `regenie_bsize_step2`     | Size of the genotype blocks |  400 |
| `regenie_sample_file`     | Sample file corresponding to input BGEN file |  empty |
| `regenie_skip_predictions`     | Skip Regenie Step 1 predictions |  false |
| `regenie_min_imputation_score`     | Minimum imputation info score (IMPUTE/MACH R^2)  |  0.00 |
| `regenie_min_mac`     | Minimum minor allele count  |  5 |
| `regenie_range`     | Apply Regenie only on specify region |  '' [format=CHR:MINPOS-MAXPOS] |
| `min_pvalue`     | Filter results with logp10 < 2 |  2 |
| `tophits`     | # of tophits (sorted by pvalue) with annotation |  50 |


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
