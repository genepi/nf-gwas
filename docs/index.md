---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: home
title: Home

nav_order: 1
---

# Welcome to GWAS-Regenie!

A nextflow pipeline to perform genome-wide association studies (GWAS) using [regenie](https://github.com/rgcgithub/regenie).
{: .fs-6 .fw-300 }

[Get started now](getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 }&nbsp;&nbsp;
[View it on GitHub](https://github.com/genepi/gwas-regenie){: .btn .fs-5 .mb-4 .mb-md-0 }

---

The pipeline takes imputed bgen (e.g. from UK Biobank) or VCF files (e.g. from [Michigan Imputation Server](https://imputationserver.sph.umich.edu/)) as an input and outputs association results, annotated tophits and an RMarkdown report including numerous plots and statistics. The pipeline currently includes the following steps:


1. Validate phenotype and covariate file (e.g. check file format, replace empty values with NA, create summary statistics)

2. Convert VCF imputed data into the [plink2 file format](https://github.com/chrchang/plink-ng/blob/master/pgen_spec/pgen_spec.pdf) (optional).

3. Prune micro-array data using [plink2](https://www.cog-genomics.org/plink/2.0/) (optional).

4. Filter micro-array data using plink2 based on MAF, MAC, HWE, genotype missingess and sample missingness.

5. Run [regenie](https://github.com/rgcgithub/regenie) and tabix results (e.g. to use with LocusZoom).

6. Parse regenie log and create summary statistics.

7. Filter regenie results by pvalue.

8. Annotate filtered results using [bedtools closest](https://bedtools.readthedocs.io/en/latest/content/tools/closest.html).

9. Create a RMarkdown report per phenotype including a annotated manhattan plot, qq plot, top genes, phenotype statistics and parsed log files.
