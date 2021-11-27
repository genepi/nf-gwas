---
layout: page
title: Pipeline Overview
parent: GWAS-Regenie 101
nav_order: 2
---

## Pipeline Overview

The GWAS-regenie pipeline performs whole genome regression modeling using [regenie](https://github.com/rgcgithub/regenie). For profound details on regenie, I suggest to read the paper by Mbatchou et al. but it can be used for quantitative and binary traits and first builds regression models according to the leave-one-chromosome-out (LOCO) scheme that are then used in the second step (which tests the association of each SNP with the phenotype) as covariates ([see regenie paper](https://doi.org/10.1038/s41588-021-00870-7)). The advantage is that it is computationally efficient and fast meaning that it can also be used on very large datasets such as UK Biobank.

### Error-prone data preparation steps are performed by the pipeline

However, before you actually perform a GWAS, you need to properly prepare your data including converting file formats, filtering data and correct preparation of phenotypes and covariates. These steps are tedious and prone to error - and can also be very time consuming if it's your first time working with command line programs. Luckily, the pipeline does some of the work for you and summarizes these preparation steps in the end in a report file:

1. It validates the phenotype and (optional) covariate files that you prepared
2. For step 1 regenie developers recommend to use directly genotyped variants that have passed quality control (QC). The pipeline performs the QC for you, based on minor allele frequency and count, genotype missingness, Hardy-Weinberg equilibrium and sample missingness. In addition, the regenie developers do not recommend to use >1M SNPs for step 1. Therefore, the pipeline can additionally perform pruning before step 1 of regenie is run. By default, certain QC thresholds are set and pruning is disabled but of course you can adapt the QC thresholds and pruning settings.
3. In step 2 all available genotypes should be used. If you have for example imputed your data with the Michigan Imputation Server, it is in the VCF format, that is not supported by regenie. The pipeline can convert your VCF imputed data into the correct file format. In addition, you can also set a threshold for the imputation score and the minor allele count for the imputed variants that are included in step 2.

### The pipeline automatically creates Manhattan and QQ plots and annotates your results

In addition to performing these data preparation steps, the pipeline also performs redundant data analysis steps. This directly gives you an overview about your results:

1. After performing a GWAS you first want to see the Manhattan plot, the QQ plot and maybe look at the nearest genes and effect sizes of tophits. The pipeline automatically generates an html report containing all these plots and lists. In addition, it contains all the information about the data pre-processing and regenie steps. This allows you to check if everything was performed as intended and also increases reproducibility because all the information about the GWAS is summarized in one file.
2. Regenie gives you the GWAS summary statistics as a large file with the ending *.regenie.gz*. If your computer does not have so much RAM, loading this file for example into R to perform some further analyses can take quite long. The pipeline additionally outputs you a file with the ending *.filtered.annotated.txt.gz*. This file is much smaller because it only contains the summary SNPs filtered for a minimum ‑log<sub>10</sub>(P) (by default =5) and in addition the nearest genes have been annotated to these SNPs.

### Run pipeline with Nextflow
And last but not least it is also important to mention that this pipeline is built with the workflow manager [Nextflow](https://www.nextflow.io/). To use the pipeline, you don't need to know how it works let alone build one on your own but I think one important advantage is helpful to know: The software that is needed for all the steps described above is downloaded when the pipeline is initiated and the software is stored in a *container*. So no matter if you perform the data analysis on different computers or if you need to rerun it in two years: As long as you use the same input data and the same configuration of the pipeline, you always get the same results. This further increases reproducibility and saves a lot of time if you suddenly need to work with a different computer or server.
