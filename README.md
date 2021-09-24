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

## Parameters

### Required parameters


| Option        |Description          | Value [default] |
| ------------- |-------------| -------------| 
| `params.project`     | Project name | my-gwas | 
| `params.output`     | Output directory | output/${params.project}) |
| `params.genotypes_typed`     | Path to the array genotypes (single merged file in plink format).  | /path/to/allChrs.{bim,bed,fam} |
| `params.genotypes_imputed`     | Path to imputed genotypes in VCF or BGEN format) | /path/to/vcf/\*vcf.gz or /path/to/vcf/\*bgen |
| `params.genotypes_imputed_format `     | Input file format of imputed genotypes   | vcf,bgen [bgen] |
| `params.build`     | Imputed genotypes build format | hg19 / hg38 [hg19] |
| `params.phenotypes_filename `     | Phenotype file | |
| `params.phenotypes_columns`     | Phenotype columns | ["phenoColumn1","phenoColumn2","phenoColumn3",...] |
| `params.phenotypes_binary_trait`     | Binary trait? | false, true [false] | 

### Addtional phenotype parameters

| Option        |Description          | Value |
| ------------- |-------------| -------------| 
| `params.covariates_filename`     | Covariate file | |
| `params.covariates_columns`     | Covariate columns |  ["covar1","covar2","covar3",...] |
| `params.phenotypes_delete_missing_data`     | Removing samples with missing data at any of the phenotypes | **false**, true |


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
