---
layout: page
title: "Getting Started"
permalink: /getting-started/
nav_order: 2
---

# Getting Started

----

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
