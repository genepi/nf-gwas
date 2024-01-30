---
layout: page
title: "Getting Started"
nav_order: 2
---

## Getting Started

1. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=22.10.4) 

2. Install [Docker](https://docs.docker.com/get-docker/) or [Singularity](https://sylabs.io/). 

**Note for Windows users**: This [step-by-step tutorial](https://www.nextflow.io/blog/2021/setup-nextflow-on-windows.html) helps you to set up Nextflow on your local machine.

3. Run the pipeline on a test dataset to validate your installation.

    ```
    nextflow run genepi/nf-gwas -r <latest-tag> -profile test,docker
    ```
**Note:** Click [here](https://github.com/genepi/nf-gwas/tags) to replace the `<latest-tag>` with the actual version you want to run (e.g. `-r v1.0.0`). 

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


2. Run the pipeline on your data with your configuration file
    ```
    nextflow run genepi/nf-gwas -c project.config -r v<[latest tag](https://github.com/genepi/nf-gwas/tags)> -profile <docker,singularity>
    ```

**Note:** The slurm profiles require that (a) singularity is installed on all nodes and (b) a shared file system path as a working directory.
