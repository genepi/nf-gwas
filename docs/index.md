---
layout: home
title: Home
nav_order: 1
---

# Welcome to nf-gwas!

A Nextflow pipeline to perform genome-wide association studies (GWAS).
{: .fs-6 .fw-300 }


[Get started now](getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 }&nbsp;&nbsp;
[View it on GitHub](https://github.com/genepi/nf-gwas){: .btn .fs-5 .mb-4 .mb-md-0 }


---

![image](images/Figure2_example_report.png)

---
This cloud-ready GWAS pipeline allows you to run **single variant tests**, **gene-based tests**  and **interaction testing** using [REGENIE](https://github.com/rgcgithub/regenie) in an automated and reproducible way.

For single variant tests, the pipeline works with BGEN (e.g. from UK Biobank) or VCF files (e.g. from [Michigan Imputation Server](https://imputationserver.sph.umich.edu/)). For gene-based tests, we currently support BED files as an input.
The pipeline outputs association results (tabixed, works with e.g. LocusZoom out of the box), annotated loci tophits and an interactive HTML report provding statistics and plots.

The single-variant pipeline currently includes the following steps:


1. Validate phenotype and covariate file (e.g. check file format, replace empty values with NA, create summary statistics)

2. Convert imputed data in VCF format into the [plink2 file format](https://github.com/chrchang/plink-ng/blob/master/pgen_spec/pgen_spec.pdf) (optional).

3. Prune micro-array data using [plink2](https://www.cog-genomics.org/plink/2.0/) (optional).

4. Filter micro-array data using plink2 based on MAF, MAC, HWE, genotype missingess and sample missingness.

5. Run [regenie](https://github.com/rgcgithub/regenie) and tabix results to use with LocusZoom.

6. Parse regenie log and create summary statistics.

7. Filter regenie results by pvalue.

8. Annotate filtered results using [genomic-utils](https://github.com/genepi/genomic-utils) and genes from [GENCODE](https://www.gencodegenes.org).

9. Create a HTML report per phenotype including the annotated manhattan plot, qq plot, top loci, phenotype statistics and parsed log files.
