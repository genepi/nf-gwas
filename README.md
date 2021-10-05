# GWAS-Regenie

[![GWAS_Regenie](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml)

A nextflow pipeline to perform whole genome regression modelling using [regenie](https://github.com/rgcgithub/regenie).

## Pipeline Overview

The pipeline takes imputed bgen (e.g. from UK Biobank) or VCF files (e.g. from Michigan Imputation Server) as an input and outputs association results, annotated tophits and an RMarkdown report including numerous plots and statistics. 

1) Convert VCF imputed data into the [plink2 format](https://github.com/chrchang/plink-ng/blob/master/pgen_spec/pgen_spec.pdf).
2) Prune genotyped data using [plink2](https://www.cog-genomics.org/plink/2.0/) (optional).
3) Filter genotyped data using plink2 based on MAF, MAC, HWE, genotype missingess and sample missingness. 
4) Run [regenie](https://github.com/rgcgithub/regenie).
5) Filter regenie results by pvalue using a [JBang](https://github.com/jbangdev/jbang) script.
6) Extract tophits and annotate them using [bedtools closest](https://bedtools.readthedocs.io/en/latest/content/tools/closest.html).
7) Create [RMarkdown report](https://rmarkdown.rstudio.com/) including phenotype statistics, manhattan plot and qq plot.

## Status
The pipeline is currently under development (v0.1.6). 

## Quick Start

1) Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=21.04.0)

2) Run the pipeline on a test dataset

```
nextflow run genepi/gwas-regenie -r v0.1.6 -profile test,<docker,singularity>
```

3) Run the pipeline on your data

```
nextflow run genepi/gwas-regenie -c <nextflow.config> -r v0.1.6 -profile <docker,singularity>
```

Pleas click [here](tests) for available test config files. 

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
| `regenie_range`     |  ' ' | Apply regenie only on a specify region [format=CHR:MINPOS-MAXPOS] | 
| `min_pvalue`     |   2 | Filter results with logp10 < 2 |
| `tophits`     |   50 | # of tophits (sorted by pvalue) with annotation |
| `manhattan_plot_ylimit`     |   0 | Limit y axis in Manhattan plot for large p-values |

## Development

```
git clone https://github.com/genepi/gwas-regenie
cd gwas-regenie
docker build -t genepi/gwas-regenie . # don't ignore the dot
nextflow run main.nf -profile test,standard
```

## License
gwas-regenie is MIT Licensed.

## Contact
If you have any questions about the regenie nextflow pipeline please contact
* [Sebastian Schönherr](mailto:sebastian.schoenherr@i-med.ac.at)
* [Lukas Forer](mailto:lukas.forer@i-med.ac.at)

