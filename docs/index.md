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

[Get started now](#getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 }&nbsp;&nbsp;
[View it on GitHub](https://github.com/genepi/gwas-regenie){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Getting Started

1. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=21.04.0)

2. Install [Docker](https://docs.docker.com/get-docker/) or [Singularity](https://sylabs.io/)

3. Run the pipeline on a test dataset using Docker to validate your installation

    ```
    nextflow run genepi/gwas-regenie -r v0.1.14 -profile test,docker
    ```

4. Run the pipeline on your data

    ```
    nextflow run genepi/gwas-regenie -c <nextflow.config> -r v0.1.14 -profile docker
    ```

**Note:** The slurm profiles require that (a) singularity is installed on all nodes and (b) a shared file system path as a working directory.
