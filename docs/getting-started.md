---
layout: page
title: "Getting Started"
nav_order: 2
---

## Getting Started

1. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=21.04.0).
**Windows users**: this [step-by-step](https://www.nextflow.io/blog/2021/setup-nextflow-on-windows.html) tutorial could make your life much easier.

2. Install [Docker](https://docs.docker.com/get-docker/) or [Singularity](https://sylabs.io/).

3. Run the pipeline on a test dataset using Docker to validate your installation.

    ```
    nextflow run genepi/nf-gwas -r v<[latest tag](https://github.com/genepi/nf-gwas/tags)> -profile test,<docker,singularity>
    ```

### Run the pipeline on your data

1. Create a Nextflow configuration file (e.g. `project.config`) and set the required parameters and paths. A complete list of parameters can be found [here](params/params.md).

    ```
    params {
        project                       = 'test-gwas'
        genotypes_prediction          = 'tests/input/example.{bim,bed,fam}'
        genotypes_association         = 'tests/input/example.bgen'
        genotypes_build               = 'hg19'
        genotypes_association_format  = 'bgen'
        phenotypes_filename           = 'tests/input/phenotype.txt'
        phenotypes_columns            = 'Y1,Y2'
        phenotypes_binary_trait       = false
        regenie_test                  = 'additive'
        annotation_min_log10p         = 2
    }
    ```


2. Run the pipeline with your configuration file
    ```
    nextflow run genepi/nf-gwas -c project.config -r v1.0.0 -profile <docker,singularity>
    ```

**Note:** The slurm profiles require that (a) singularity is installed on all nodes and (b) a shared file system path as a working directory.
