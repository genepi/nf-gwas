---
layout: page
title: "Getting Started"
permalink: /getting-started/
nav_order: 2
---

## Getting Started

1. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=21.04.0)

2. Install [Docker](https://docs.docker.com/get-docker/) or [Singularity](https://sylabs.io/)

3. Run the pipeline on a test dataset using Docker to validate your installation

    ```
    nextflow run genepi/gwas-regenie -r v0.1.14 -profile test,docker
    ```

### Run the pipeline on your data

1. Create a configuration file (e.g. `project.config`) and set the required parameters and paths:

    ```
    params {
        project                       = 'test-gwas'
        genotypes_array               = 'tests/input/example.{bim,bed,fam}'
        genotypes_imputed             = 'tests/input/example.bgen'
        genotypes_build               = 'hg19'
        genotypes_imputed_format      = 'bgen'
        phenotypes_filename           = 'tests/input/phenotype.txt'
        phenotypes_columns            = 'Y1,Y2'
        phenotypes_binary_trait       = false
        regenie_test                  = 'additive'
        annotation_min_log10p         = 2
    }
    ```

   A list of all parameters can be found [here](params/params.md)

2. Run the pipeline with your configuration file
    ```
    nextflow run genepi/gwas-regenie -c project.config -r v0.1.14 -profile docker
    ```

**Note:** The slurm profiles require that (a) singularity is installed on all nodes and (b) a shared file system path as a working directory.
