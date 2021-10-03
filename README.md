# GWAS-Regenie

[![GWAS_Regenie](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml)

A nextflow pipeline to perform whole genome regression modelling using [regenie](https://github.com/rgcgithub/regenie).

## Pipeline Overview

1) Convert imputed data into [pgen](https://github.com/chrchang/plink-ng/blob/master/pgen_spec/pgen_spec.pdf) (VCF only).
2) Prune genotyped data using [plink2](https://www.cog-genomics.org/plink/2.0/) (optional).
3) Filter genotyped data using plink2 based on MAF, MAC, HWE, genotype missingess and sample missingness. 
4) Run [Regenie](https://github.com/rgcgithub/regenie) Step 1 and Step 2
5) Filter regenie results  by pvalue using [JBang](https://github.com/jbangdev/jbang).
6) Annotate top hits using [bedops](https://bedops.readthedocs.io/en/latest/).
7) Create [RMarkdown report](https://rmarkdown.rstudio.com/) including phenotype information, manhattan plot and qq plot.


## Quick Start

1) Install (Nextflow)[https://www.nextflow.io/docs/latest/getstarted.html#installation] (>=21.04.0)

2) Run the pipeline on a test dataset

```
nextflow run genepi/gwas-regenie -r v0.1.4 -profile test,<docker,singularity>
```
3) Run the pipeline on your data

```
nextflow run genepi/gwas-regenie -c <nextflow.config> -r v0.1.4 -profile <docker,singularity>
```

Pleas click [here](tests) for available config files. 


## Parameters

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
| `outdir`     | "output/${params.project}" | Output directory   
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
| `regenie_range`     |  ' ' [format=CHR:MINPOS-MAXPOS] | Apply Regenie only on specify region | 
| `min_pvalue`     |   2 | Filter results with logp10 < 2 |
| `tophits`     |   50 | # of tophits (sorted by pvalue) with annotation |


## License
gwas-regenie is MIT Licensed.

## Contact
If you have any questions about the regenie nextflow pipeline please contact
* [Sebastian Schönherr](mailto:sebastian.schoenherr@i-med.ac.at)
* [Lukas Forer](mailto:lukas.forer@i-med.ac.at)

