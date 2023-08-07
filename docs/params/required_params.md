---
layout: page
title: "Required Parameters"
parent: Parameters
nav_order: 1
---

## Required Parameters
Our pipeline supports single-variant and gene-based tests. Depending on the use-case, different parameters must be set.

### All Tests

| Option        | Value          | Description  |
| ------------- |-----------------| -------------|
| `project`     | my-project-name | Name of the project |
| `genotypes_prediction (deprecated: genotypes_array)`     |  /path/to/allChrs.{bim,bed,fam} | Path to the array genotypes (single merged file in plink format).  |
| `genotypes_association (deprecated: genotypes_imputed)`     |  /path/to/vcf/\*vcf.gz or /path/to/bgen/\*bgen | Path to imputed genotypes in VCF or BGEN format) |
| `genotypes_association_format (deprecated: genotypes_imputed_format)`     | VCF *or* BGEN | Input file format of imputed genotypes   |
| `genotypes_build`     | hg19 *or* hg38 | Imputed genotypes build format |
| `phenotypes_filename `     | /path/to/phenotype.txt | Path to phenotype file |
| `phenotypes_columns`     | 'phenoColumn1,phenoColumn2,phenoColumn3' | List of phenotypes |
| `phenotypes_binary_trait`     | false, true | Binary trait? |

### Single-variant Tests Only

| Option        | Value          | Description  |
| ------------- |-----------------| -------------|
| `regenie_test`     | additive, recessive *or* dominant |  Define test |

### Gene-based Tests Only
The parameters *regenie_gene_anno*, *regenie_gene_setlist* and *regenie_gene_masks* are all regenie parameters. Please click [here](https://rgcgithub.github.io/regenie/options/#gene-based-testing) to learn more about this feature.

| Option        | Value          | Description  |
| ------------- |-----------------| -------------|
| `regenie_run_gene_based_tests`     | true (default: false) | Activate gene-based testing  |
| `regenie_gene_anno`     | /path/to/*.annotation |  File with variant annotations for each set |
| `regenie_gene_setlist`     | /path/to/*.setlist|  File listing variant sets
 |
| `regenie_gene_masks`     | /path/to/*.masks |  File with mask definitions using the annotations defined in regenie_gene_anno |

### Interaction Tests
Starting from regenie v3.0, you can perform scans for interactions (either GxE or GxG). Please click [here](https://rgcgithub.github.io/regenie/options/#interaction-testing) to learn more about this feature.

| Option        | Value          | Description  |
| ------------- |-----------------| -------------|
| `regenie_run_interaction_tests` | true (default: false) | Activate interaction testing  |
| `regenie_interaction`     | null |  to run GxE test specifying the interacting covariate |
| `regenie_interaction_snp`   | null |  to run GxG test specifying the interacting variant |

### Conditional analyses
Starting from regenie v3.0, you can specify genetic variants to add to the set of covariates when performing association testing. Please click [here](https://rgcgithub.github.io/regenie/options/#conditional-analyses) to learn more about this feature.

| Option        | Value          | Description  |
| ------------- |-----------------| -------------|
| ` regenie_condition_list`     | null | file with list of variants to condition on  |
