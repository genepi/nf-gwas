---
layout: page
title: "Optional Parameters"
parent: Parameters
nav_order: 2
---

## Optional Parameters

| Option        |Default          | Description |
| ------------- |-----------------| -------------|
| `outdir`     | "output/${params.project}" | Output directory   
| `project_date`     | today | Date in report |  
| `covariates_filename`     |  empty | path to covariates file |
| `covariates_columns`     | empty | List of covariates |  
| `phenotypes_delete_missings`     | false | Removing samples with missing data at any of the phenotypes |
| `prune_enabled`     | false | Enable pruning step |
| `prune_maf`     | 0.01 | MAF filter |
| `prune_window_kbsize`     | 1000 | Window size |
| `prune_step_size`     | 100 | Step size (variant ct) |
| `prune_r2_threshold`     |  0.9 | Unphased hardcall R2 threshold|
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
| `regenie_firth`     |   true  | Use Firth likelihood ratio test (LRT) as fallback for p-values less than threshold |
| `regenie_firth_approx`     |  true | Use approximate Firth LRT for computational speedup |
| `regenie_force_step1`     |  false | Run regenie step 1 when >1M genotyped variants are used (not recommended) |
| `regenie_ref_first`     |  false | Specify to use the first allele as the reference allele for BGEN or PLINK bed/bim/fam file input [default is to use the last allele as the reference] |
| `annotation_min_log10p`     |   5 | Filter and annotate results with logp10 >= 5 |
| `plot_ylimit`     |   0 | Limit y axis in Manhattan/QQ plot for large p-values |
| `manhattan_annotation_enabled`     |  true | Use annotation for Manhattan plot |
