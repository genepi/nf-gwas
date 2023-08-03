---
layout: page
title: Profiles
parent: Configuration
nav_order: 3
---

## Profiles

nf-gwas provides different execution profiles which can be specified with the `-profile` parameter.

`nextflow run genepi/nf-gwas -r v0.5.2 -profile test, <docker,singularity,development, slurm,slurm_with_scratch>`.

### Docker
For local runs, [Docker](https://docs.docker.com/get-docker/) is the easiest way to run the pipeline.

### Singularity
For HPC clusters, we recommend to use [Singularity](https://sylabs.io/). Singularity is also required for the Slurm profiles below.

### Slurm
Nextflow supports Slurm as an execution engine. The profile `slurm_with-scratch` includes a directive to execute the process in a temporary folder that is local to the execution node (`/tmp` by default). You can change the default location by setting `export NXF_TEMP=/your/path` on the command line before executing the pipeline.   

### Development
The profile `development` can be used to e.g. test/adapt the code and e.g. create pull requests. This profile requires that the image must be available locally.

```
git clone https://github.com/genepi/nf-gwas
cd nf-gwas
docker build -t genepi/nf-gwas . # don't ignore the dot
nextflow run main.nf -profile test,development
```
