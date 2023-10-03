# nf-gwas

[![nf-gwas](https://github.com/genepi/nf-gwas/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/nf-gwas/actions/workflows/ci-tests.yml)
[![nf-test](https://img.shields.io/badge/tested_with-nf--test-337ab7.svg)](https://github.com/askimed/nf-test)

This cloud-ready GWAS pipeline allows you to run single variant tests and gene-based tests using [REGENIE](https://github.com/rgcgithub/regenie) in an automated and reproducible way. The pipeline outputs tabixed association results (e.g. for LocusZoom), gene-annotated tophits and an interactive HTML report including numerous statistics and plots (e.g. Manhattan Plat, QQ-Plot by MAF).

![image](docs/images/Figure2_example_report.png)


## Documentation

Documentation can be found [here](https://genepi.github.io/nf-gwas/).

![image](docs/images/Figure1_MetroMap_v02.jpg)

## Citation

Please cite this preprint if you use nf-gwas:

> [Performing highly parallelized and reproducible GWAS analysis on biobank-scale data](https://www.biorxiv.org/content/10.1101/2023.08.08.552417v1).
> Sebastian Schoenherr, Johanna Schachtl-Riess, Silvia Di Maio, Michele Filosi, Marvin Mark, Claudia Lamina, Christian Fuchsberger, Florian Kronenberg, Lukas Forer
> bioRxiv 2023.08.08.552417; doi: [https://doi.org/10.1101/2023.08.08.552417](https://doi.org/10.1101/2023.08.08.552417)

## Quick Start

1) Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=22.10.4)

2) Run the pipeline on a test dataset

```
nextflow run genepi/nf-gwas -r v1.0.1 -profile test,<docker,singularity,slurm,slurm_with_scratch>
```

3) Run the pipeline on your data

```
nextflow run genepi/nf-gwas -c <nextflow.config> -r v1.0.1 -profile <docker,singularity,slurm,slurm_with_scratch>
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
nf-gwas is MIT Licensed and was developed at the [Institute of Genetic Epidemiology](https://genepi.i-med.ac.at/), Medical University of Innsbruck, Austria.

## Contact
* [Sebastian Schönherr](mailto:sebastian.schoenherr@i-med.ac.at)
* [Lukas Forer](mailto:lukas.forer@i-med.ac.at)
* [Johanna Schachtl-Riess](mailto:johanna.schachtl-riess@i-med.ac.at)
* [Silvia Di Maio](mailto:silvia.di-maio@i-med.ac.at)