# GWAS-Regenie

> Nextflow pipeline to execute Regenie, create Manhattan-Plots and annotate results

## Requirements

- Nextflow:

```
curl -s https://get.nextflow.io | bash
```

## Run Pipeline

```
nextflow run -c <config> genepi/gwas-regenie -r v0.1.1
```
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
