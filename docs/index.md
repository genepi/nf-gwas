---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: home
title: Home

nav_order: 1
---

# Welcome to GWAS-Regenie!

A nextflow pipeline to perform whole genome regression modelling using [regenie](https://github.com/rgcgithub/regenie).
{: .fs-6 .fw-300 }

[Get started now](getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 }&nbsp;&nbsp;
[View it on GitHub](https://github.com/genepi/gwas-regenie){: .btn .fs-5 .mb-4 .mb-md-0 }

---

The pipeline takes imputed bgen (e.g. from UK Biobank) or VCF files (e.g. from Michigan Imputation Server) as an input and outputs association results, annotated tophits and an RMarkdown report including numerous plots and statistics.

1. Validate phenotype and covariate file (e.g. check file format, replace empty values with NA, create summary statistics)

2. Convert VCF imputed data into the [plink2] file format (https://github.com/chrchang/plink-ng/blob/master/pgen_spec/pgen_spec.pdf).

3. Prune genotyped data using [plink2](https://www.cog-genomics.org/plink/2.0/) (optional).

4. Filter genotyped data using plink2 based on MAF, MAC, HWE, genotype missingess and sample missingness.

5. Run [regenie](https://github.com/rgcgithub/regenie) and tabix results (e.g. to use with LocusZoom).

6. Parse regenie log and create summary statistics.

7. Filter regenie results by pvalue using [JBang](https://github.com/jbangdev/jbang).

8. Annotate filtered results using [bedtools closest](https://bedtools.readthedocs.io/en/latest/content/tools/closest.html).

9. Create a [RMarkdown report](https://rmarkdown.rstudio.com/) including phenotype statistics, parsed log files manhattan plot, qq plot and top genes.
