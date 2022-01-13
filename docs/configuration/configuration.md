---
layout: page
title: Configuration
has_children: true
nav_order: 4
---

## Configuration

Before running GWAS-Regenie, a Nextflow [config file](https://github.com/genepi/gwas-regenie/blob/main/conf/test.config) must be prepared. This file includes both [pipeline parameters](parameters) and [cpus/memory directives](directives) and can be specified on the command line.
```
nextflow run genepi/gwas-regenie -c <nextflow.config> -r v0.2.1 -profile <docker,singularity,slurm,slurm_with_scratch>

```
Additionally, the correct [profile](profiles) must be specified before executing the pipeline.

If you are new to Nextflow, you can learn about Nextflow configuration files [here](https://www.nextflow.io/docs/latest/config.html) or check out our [Beginners Guide](gwas-regenie-101/beginners-guide).
