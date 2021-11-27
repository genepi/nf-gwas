---
layout: page
title: "Running the pipeline"
parent: GWAS-Regenie 101
nav_order: 3
---

### Running the GWAS-Regenie pipeline

To run the pipeline on your data, prepare the phenotype and (optional) covariate files as described by regenie (see [here](https://rgcgithub.github.io/regenie/options/#input)). In addition, you need the genotyping data for step 1 in bim,bed,fam format and your imputed genotypes in VCF or BGEN format. Transfer all these files using FileZilla to the folder of your choice on the server.

Now, you have to prepare a configuration file for the pipeline. For this, you can use any text editor but for example the text editor Atom is very convenient since it can also highlight different kinds of codes etc. The required and optional parameters for the configuration file are all listed on the [GitHub repository](https://github.com/genepi/gwas-regenie) of the pipeline. To make your own config file, it is the easiest to copy one of the exemplary [config files](https://github.com/genepi/gwas-regenie/tree/main/tests/configs). Adapt all the paths and parameters to fit your data and save the file (e.g. as: first-gwas.config). If you added additional parameters, just make sure, that they are within the curly brackets.

Just one possibly helpful fact on the side here: as indicated on the GitHub repository, the genotypes have to be a single merged file but the imputed genotypes can also be one file per chromosome. If we have them in single files per chromosome we can put the path for example as follows into the configuration file `/home/myHome/GWAS/imputed\_data/\*vcf.gz`. The asterisk (\*) is a wildcard. So it will take all the files from the imputed\_data folder that end with `vcf.gz`.
 Now you can transfer the file via FileZilla to your folder of choice on the server (as an example let's say we put the `first-gwas.config` into the folder `/home/myHome/GWAS`).

To run the pipeline with the `first-gwas.config` configuration file, we simply change the working directory to the GWAS folder (`cd /home/myHome/GWAS`) and type in the following command:
```
nextflow run genepi/gwas-regenie -c first-gwas.config -r v0.1.13 -profile singularity -bg
```
In more detail:

* `nextflow` tells the command line to start Nextflow

* `run genepi/gwas-regenie` tells Nextflow which pipeline it should access

* `-c first-gwas.config`; tells the pipeline which configuration file it should use (just exchange first-gwas.config with the name of your config file)

* `-r v0.1.13` tells which version of the pipeline should be used (you can check the number of the latest version on the GitHub repository of the pipeline and change it accordingly)

* `-profile singularity` this tells Nextflow which configuration profile it should use and you can find the available options on the GitHub repository. However, as long as you're not familiar with different types of containerization software, parallelization etc., just use singularity (I am doing the same)

* `-bg` you can also remove this option, but then, the command stops if you close your command line

That's it - your first GWAS is running! How long does it take until you get your results? This depends on many parameters: the computational power of your server, the number of samples, the number of genotyped SNPs included in step 1 and the number of imputed SNPs included in step 2… it can take from a few hours to days (or weeks). If you use the command `htop`, it will display the current processes that are running (quit by typing in `q`).

If something is not working, Nextflow will print an error on the command line. If everything works and your GWAS is finished you will find a folder called `output` in the directory of your configuration file. With FileZilla you can copy this folder onto your local computer. Within this folder, you will find the html report with the plots and summaries, the result files (whole summary statistics and the filtered annotated ones) and some other output files.