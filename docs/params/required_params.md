---
layout: page
title: "Required Parameters"
parent: Parameters
permalink: /required-params/
nav_order: 1
---

## Required Parameters

| Option        | Value          | Description  |
| ------------- |-----------------| -------------|
| `project`     | my-project-name | Name of the project |
| `genotypes_array`     |  /path/to/allChrs.{bim,bed,fam} | Path to the array genotypes (single merged file in plink format).  |
| `genotypes_imputed`     |  /path/to/vcf/\*vcf.gz or /path/to/bgen/\*bgen | Path to imputed genotypes in VCF or BGEN format) |
| `genotypes_imputed_format `     | vcf *or* bgen | Input file format of imputed genotypes   |
| `genotypes_build`     | hg19 *or* hg38 | Imputed genotypes build format |
| `phenotypes_filename `     | /path/to/phenotype.txt | Path to phenotype file |
| `phenotypes_columns`     | 'phenoColumn1,phenoColumn2,phenoColumn3' | List of phenotypes |
| `phenotypes_binary_trait`     | false, true | Binary trait? |
| `regenie_test`     | additive, recessive *or* dominant |  Define test |
