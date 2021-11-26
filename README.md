# GWAS-Regenie

[![GWAS_Regenie](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/gwas-regenie/actions/workflows/ci-tests.yml)

A nextflow pipeline to perform whole genome regression modelling using [regenie](https://github.com/rgcgithub/regenie).

## Documentation
Documentation can be found [here](https://genepi.github.io/gwas-regenie/).

## Quick Start

1) Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=21.04.0)

2) Run the pipeline on a test dataset

```
nextflow run genepi/gwas-regenie -r v0.1.14 -profile test,<docker,singularity,slurm,slurm_with_scratch>
```

3) Run the pipeline on your data

```
nextflow run genepi/gwas-regenie -c <nextflow.config> -r v0.1.14 -profile <docker,singularity,slurm,slurm_with_scratch>
```
**Note:** The slurm profiles require that (a) singularity is installed on all nodes and (b) a shared file system path as a working directory.

Please click [here](tests) for available test config files.


## Development

```
git clone https://github.com/genepi/gwas-regenie
cd gwas-regenie
docker build -t genepi/gwas-regenie . # don't ignore the dot
nextflow run main.nf -profile test,development
```

## License
gwas-regenie is MIT Licensed.

## Contact
If you have any questions about the regenie nextflow pipeline please contact
* [Sebastian Schönherr](mailto:sebastian.schoenherr@i-med.ac.at)
* [Lukas Forer](mailto:lukas.forer@i-med.ac.at)
