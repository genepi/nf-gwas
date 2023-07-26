# nf-gwas

[![nf-gwas](https://github.com/genepi/nf-gwas/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/nf-gwas/actions/workflows/ci-tests.yml)
[![nf-test](https://img.shields.io/badge/tested_with-nf--test-337ab7.svg)](https://github.com/askimed/nf-test)

This cloud-ready GWAS pipeline allows you to run single variant tests and gene-based tests using [regenie](https://github.com/rgcgithub/regenie) in an automated and reproducible way. The pipeline outputs tabixed association results (e.g. for LocusZoom), gene-annotated tophits and an interactive HTML report including numerous statistics and plots (e.g. Manhattan Plat, QQ-Plot by MAF).

## Documentation
Documentation can be found [here](https://genepi.github.io/nf-gwas/).

## Quick Start

1) Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=21.04.0)

2) Run the pipeline on a test dataset

```
nextflow run genepi/nf-gwas -r v0.7.1 -profile test,<docker,singularity,slurm,slurm_with_scratch>
```

3) Run the pipeline on your data

```
nextflow run genepi/nf-gwas -c <nextflow.config> -r v0.7.1 -profile <docker,singularity,slurm,slurm_with_scratch>
```

Please click [here](tests) for available test config files.

## Development
```
git clone https://github.com/genepi/nf-gwas
cd nf-gwas
docker build -t genepi/nf-gwas . # don't ignore the dot
nextflow run main.nf -profile test,development
```

## nf-test
nf-gwas makes use of [nf-test](https://github.com/askimed/nf-test), a unit-style test framework for Nextflow.
```
cd nf-gwas
curl -fsSL https://code.askimed.com/install/nf-test | bash
./nf-test test
```

## License
nf-gwas is MIT Licensed.

## Contact
* [Sebastian Schönherr](mailto:sebastian.schoenherr@i-med.ac.at)
* [Lukas Forer](mailto:lukas.forer@i-med.ac.at)
