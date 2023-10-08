---
layout: page
title: "Optional Parameters"
parent: Parameters
nav_order: 2
---

## Optional Parameters

### General

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `outdir`     | "output/${params.project}" | Output directory   
| `project_date`     | today | Date in report |  
| `covariates_filename`     |  empty | path to covariates file |
| `covariates_columns`     | empty | List of covariates |  
| `covariates_cat_columns`     | empty | List of categorical covariates |  
| `phenotypes_delete_missings`     | false | Removing samples with missing data at any of the phenotypes |
| `phenotypes_apply_rint`     | false | Apply Rank Inverse Normal Transformation (RINT) to quantitative phenotypes in both steps |
| `target_build`     | empty | Specify the desired target_build (hg19 or hg38) of your data. In case it'S different from the input data, lift-over is executed |

### Chunking
nf-gwas allows to split your prediction and association data in smaller chunks to utilize large-scale clusters.

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `genotypes_association_chunk_size`     | 0 | Desired chunksize in bases. if 0, split by chromosomes in regenie_step2 | 
| `genotypes_association_chunk_strategy`     | 'RANGE' | Chunking strategy by range or by variants (RANGE or VARIANTS) | 
| `genotypes_prediction_chunks`     | 0 | Chunking for regenie_step 1. If 0, no chunking of predictions | 



### Annotation and GWAS Report
For annotation, a rsid file is required. If not set, this will be downloaded each time. You can also prepare the file once and set it in your pipeline. Substitute rsbuild with hg19 or hg38. 
```console
wget https://resources.pheweb.org/rsids-v154-${rsbuild}.tsv.gz -O rsids-v154-${rsbuild}.tsv.gz
echo -e "CHROM\tPOS\tRSID\tREF\tALT" | bgzip -c > rsids-v154-${rsbuild}.index.gz
zcat rsids-v154-${rsbuild}.tsv.gz | bgzip -c >> rsids-v154-${rsbuild}.index.gz
tabix -s1 -b2 -e2 -S1 rsids-v154-${rsbuild}.index.gz
```

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `rsids_filename`     | empty | rsID file for annotation (see above) |
| `annotation_min_log10p`     | 7.3 | Annotation limit for interactive and static report |
| `annotation_peak_pval`     | 1.5 |  |
| `annotation_max_genes `     | 20 | Number of max annotated genes |

### Static Report

| Option        |Default          | Description |
| `plot_ylimit`     |   0 | Limit y axis in Manhattan/QQ plot for large p-values |
| `manhattan_annotation_enabled`     |  true | Use annotation for Manhattan plot |

### Pruning Step

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `prune_enabled`     | false | Enable pruning step |
| `prune_maf`     | 0.01 | MAF filter |
| `prune_window_kbsize`     | 1000 | Window size |
| `prune_step_size`     | 100 | Step size (variant ct) |
| `prune_r2_threshold`     |  0.9 | Unphased hardcall R2 threshold|

### Quality Control (QC) of Predictions

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `qc_maf`     |   0.01 | Minor allele frequency (MAF) filter |
| `qc_mac`     |  100 | Minor allele count (MAC) filter |  
| `qc_geno`     | 0.1 | Genotype missingess |  
| `qc_hwe`     | 1e-15 | Hardy-Weinberg equilibrium (HWE) filter |  
| `qc_mind`     | 0.1 | Sample missigness |  


### Convert VCF to PLINK format

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `vcf_conversion_split_id`     | false | If false, family and individual IDs are set to the sample ID (using plink2 `--double-id` option). If true, split VCF by "_" into FID and IID (`--id-delim`) |  

### Prediction Step (Regenie Step 1)
The following parameters are all regenie specific. Please click [here](https://rgcgithub.github.io/regenie/options/#basic-options) to learn more about them.

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `regenie_skip_predictions`     | false | Skip regenie Step 1 predictions |  
| `regenie_force_step1`     |  false | Run regenie step 1 when >1M genotyped variants are used (not recommended) |
| `regenie_bsize_step1`     | 1000 | Size of the genotype blocks |  
| `regenie_step1_optional`     | null | Add optional regenie step 1 params not directly supported |  

### Single-variant and Gene-based Tests (Regenie Step 2)
The following parameters are all regenie specific. Please click [here](https://rgcgithub.github.io/regenie/options/#basic-options) to learn more about them.

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `regenie_bsize_step2`     | 400 | Size of the genotype blocks |  
| `regenie_firth`     |   true  | Use Firth likelihood ratio test (LRT) as fallback for p-values less than threshold |
| `regenie_firth_approx`     |  true | Use approximate Firth LRT for computational speedup |
| `regenie_step2_optional`     | null | Add optional regenie step 2 params not directly supported |  

### Single-variant Tests Only

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `regenie_sample_file`     |  empty | Sample file corresponding to input BGEN file |
| `regenie_min_imputation_score`     |  0.00 | Minimum imputation info score (IMPUTE/MACH R^2)  |
| `regenie_min_mac`     |  5 | Minimum minor allele count  |
| `regenie_ref_first`     |  false | Specify to use the first allele as the reference allele for BGEN or PLINK bed/bim/fam file input [default is to use the last allele as the reference] |

### Gene-based Tests Only
The following gene-based parameters are all regenie specific. Please click [here](https://rgcgithub.github.io/regenie/options/#gene-based-testing) to learn more about this feature.

| Option        |Default          | Description |

| ------------- |-----------------| -------------|
| `regenie_gene_aaf`     |  1 % | comma-separated list of AAF upper bounds to use when building masks |
| `regenie_gene_test`     |  - | comma-separated list of SKAT/ACAT-type tests to run|
| `regenie_gene_joint`     |  - | comma-separated list of joint tests to apply on the generated burden masks |
| `regenie_gene_build_mask`     |  max | build masks using the maximum number of ALT alleles across sites, or the sum of ALT alleles ('sum'), or thresholding the sum to 2 ('comphet') |
| `regenie_write_bed_masks`     |  - | write mask to PLINK bed format (does not work when building masks with 'sum') |
| `regenie_gene_vc_mac_thr`     |  10 | MAC threshold below which to collapse variants in SKAT/ACAT-type tests |
| `regenie_gene_vc_max_aaf`     |  100% | AAF upper bound to use for SKAT/ACAT-type tests |

### Interaction Tests Only
The following interaction test parameters are all regenie specific. Please click [here](https://rgcgithub.github.io/regenie/options/#interaction-testing) to learn more about this feature.

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `regenie_rare_mac`     |  1000 | minor allele count (MAC) threshold below which to use HLM method for QTs |
| `regenie_no_condtl`     |  false | to print out all the main effects from the interaction model |
| `regenie_force_condtl`     |  false | to include the interacting SNP as a covariate in the marginal test |


