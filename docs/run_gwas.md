---
layout: post
title: "Run your first GWAS"
permalink: /run-your-first-gwas/
nav_order: 6
---

# Running the gwas-regenie nextflow pipeline – Lessons learned from a biologist
*by Johanna Schachtl-Riess*

---

##  Introduction

Programs to perform genome-wide association studies (GWAS) are usually run via the command line. This can be intimidating for a biologist. Take me as an example: In my bachelor and master I've studied molecular medicine. So my formal training focused on understanding pathophysiological processes in the human body and how to perform wet-lab experiments, I never had to use the command line. Nevertheless, I recently ran my first GWAS with this gwas-regenie nextflow pipeline ([https://github.com/genepi/gwas-regenie](https://github.com/genepi/gwas-regenie)). Here, I want to first introduce this pipeline through the lens of a biologist and second share with you *my setup*. Since I am working on a Windows computer, I need to access a remote Linux server to run the pipeline. So this section will be about the kind of tasks that are *so basic that bioinformaticians don't even talk about them*. I guess this is like describing how to pipet for a trained wet-lab biologist. However, I hope it will show you that if you follow these steps you can run your first GWAS without any prior knowledge in bioinformatics in no time :).

## General setup of the pipeline

The pipeline performs whole genome regression modeling using regenie ([https://github.com/rgcgithub/regenie](https://github.com/rgcgithub/regenie)). For profound details on regenie, I suggest to read the paper by Mbatchou et al. but it can be used for quantitative and binary traits and first builds regression models according to the leave-one-chromosome-out (LOCO) scheme that are then used in the second step (which tests the association of each SNP with the phenotype) as covariates ([https://doi.org/10.1038/s41588-021-00870-7](https://doi.org/10.1038/s41588-021-00870-7)). The advantage is that it is computationally efficient and fast meaning that it can also be used on very large datasets such as UK Biobank.

### Error-prone data preparation steps are performed by the pipeline

However, before you actually perform a GWAS, you need to properly prepare your data including converting file formats, filtering data and correct preparation of phenotypes and covariates. These steps are tedious and prone to error - and can also be very time consuming if it's your first time working with command line programs. Luckily, the pipeline does some of the work for you and summarizes these preparation steps in the end in a report file:

1. It validates the phenotype and (optional) covariate files that you prepared
2. For step 1 regenie developers recommend to use directly genotyped variants that have passed quality control (QC). The pipeline performs the QC for you, based on minor allele frequency and count, genotype missingness, Hardy-Weinberg equilibrium and sample missingness. In addition, the regenie developers do not recommend to use \&gt;1M SNPs for step 1. Therefore, the pipeline can additionally perform pruning before step 1 of regenie is run. By default, certain QC thresholds are set and pruning is disabled but of course you can adapt the QC thresholds and pruning settings.
3. In step 2 all available genotypes should be used. If you have for example imputed your data with the Michigan Imputation Server, it is in the VCF format, that is not supported by regenie. The pipeline can convert your VCF imputed data into the correct file format. In addition, you can also set a threshold for the imputation score and the minor allele count for the imputed variants that are included in step 2.

### The pipeline automatically creates Manhattan and QQ plots and annotates your results

In addition to performing these data preparation steps, the pipeline also performs redundant data analysis steps. This directly gives you an overview about your results:

1. After performing a GWAS you first want to see the Manhattan plot, the QQ plot and maybe look at the nearest genes and effect sizes of tophits. The pipeline automatically generates an html report containing all these plots and lists. In addition, it contains all the information about the data pre-processing and regenie steps. This allows you to check if everything was performed as intended and also increases reproducibility because all the information about the GWAS is summarized in one file.
2. Regenie gives you the GWAS summary statistics as a large file with the ending `.regenie.gz`. If your computer does not have so much RAM, loading this file for example into R to perform some further analyses can take quite long. The pipeline additionally outputs you a file with the ending `.filtered.annotated.txt.gz`. This file is much smaller because it only contains the summary SNPs filtered for a minimum ‑log10(P) (by default =5) and in addition the nearest genes have been annotated to these SNPs.

## Executing the pipeline with nextflow
And last but not least it is also important to mention that this pipeline is built with the workflow manager Nextflow ([https://www.nextflow.io/](https://www.nextflow.io/)). To use the pipeline, you don't need to know how it works let alone build one on your own but I think one important advantage is helpful to know: The software that is needed for all the steps described above is downloaded when the pipeline is initiated and the software is stored in a `container`. So no matter if you perform the data analysis on different computers or if you need to rerun it in two years: As long as you use the same input data and the same configuration of the pipeline, you always get the same results. This further increases reproducibility and saves a lot of time if you suddenly need to work with a different computer or server.

## Mastering the basic tasks
As mentioned in the beginning, I am working on a Windows computer, so I cannot run the pipeline locally. However, my institute has a Linux server on which Nextflow is installed. So the first steps for you are to 1) gain access to a server, a Linux computer that you can access remotely or a cluster and 2) ask the administrator to install Nextflow on it (Version ≥ 21.04.0; [https://www.nextflow.io/docs/latest/getstarted.html#installation](https://www.nextflow.io/docs/latest/getstarted.html#installation)).

### Accessing a remote server

To access the server, you only need two programs: 1) a SSH client (I am using Windows PowerShell, it is usually pre-installed on Windows computers) to navigate within the server and to execute commands and 2) a so-called multi-platform FTP client (I am using FileZilla) to transfer files from your computer to the server and vice versa. To access the server with PowerShell you only have to type in `ssh USERNAME@SERVER`. After pressing enter you only have to type in your password, press enter again, and you are connected to the server. The same applies to the FTP client: Just put in server, username, password and port as they were given to you by the administrator.

### Getting accommodated with Linux/the command line

So with PowerShell you can now navigate within the server using `bash shell` commands. The system is organized as a tree-like file system with a root branching into different folders (Unix file system). There are a lot of great video tutorials and basic courses available for free, but to run the pipeline just reading the paragraph below will be enough.

Entering `pwd` will print the present working directory, `ls` will list the files and directories in the present working directory and `cd` will change your working directory. Just try them out, you cannot break anything :). If you don't put anything after `cd`, it will move you to your home directory (the working directory when you enter the server via PowerShell). If you want to navigate to another folder, you can put an absolute or relative path after `cd`. For example: If `pwd` tells you that you are in `/home/myHome` and via `ls` you found out that in *myHome* there is the folder *Project1*, you can navigate there either by entering `cd Project1` (relative path) or `cd /home/myHome/Project1` (absolute path). If you now want to navigate back to your *myHome* folder instead of using the absolute path you can also type in `cd ..` since this command always moves into the parent folder of your current location. One last command: Lets say you are in *myHome* and you want to create a new folder called *GWAS*. For this just enter `mkdir GWAS`. If you now use `ls`, you should see the folder and you should be able to navigate there with `cd GWAS`.

### Running the gwas pipeline

To run the pipeline on your data, prepare the phenotype and (optional) covariate files as described by regenie ([https://rgcgithub.github.io/regenie/options/#input](https://rgcgithub.github.io/regenie/options/#input)). In addition, you need the genotyping data for step 1 in bim,bed,fam format and your imputed genotypes in VCF or BGEN format. Transfer all these files using FileZilla to the folder of your choice on the server.

Now, you have to prepare a configuration file for the pipeline. For this, you can use any text editor but for example the text editor Atom is very convenient since it can also highlight different kinds of codes etc. The required and optional parameters for the configuration file are all listed on the github repository of the pipeline ([https://github.com/genepi/gwas-regenie](https://github.com/genepi/gwas-regenie)). To make your own config file, it is the easiest to copy one of the exemplary config files ([https://github.com/genepi/gwas-regenie/tree/main/tests](https://github.com/genepi/gwas-regenie/tree/main/tests/configs)). Adapt all the paths and parameters to fit your data and save the file (e.g. as: first-gwas.config). If you added additional parameters, just make sure, that they are within the curly braces.
 Just one possibly helpful fact on the side here: as indicated on the github repository, the genotypes have to be a single merged file but the imputed genotypes can also be one file per chromosome. If we have them in single files per chromosome we can put the path for example as follows into the configuration file `/home/myHome/GWAS/imputed\_data/\*vcf.gz`. The asterisk (\*) is a wildcard. So it will take all the files from the imputed\_data folder that end with `vcf.gz`.
 Now you can transfer the file via FileZilla to your folder of choice on the server (as an example let's say we put the `first-gwas.config` into the folder `/home/myHome/GWAS`).

To run the pipeline with the `first-gwas.config` configuration file, we simply change the working directory to the GWAS folder (`cd /home/myHome/GWAS`) and type in the following command:
```
nextflow run genepi/gwas-regenie -c first-gwas.config -r v0.1.13 -profile singularity -bg
```

`nextflow` tells the command line to start nextflow

`run genepi/gwas-regenie` tells nextflow which pipeline it should access

`-c first-gwas.config`; tells the pipeline which configuration file it should use (just exchange first-gwas.config with the name of your config file)

`-r v0.1.13` tells which version of the pipeline should be used (you can check the number of the latest version on the github repository of the pipeline and change it accordingly)

`-profile singularity` this tells nextflow which configuration profile it should use and you can find the available options on the github repository. However, as long as you're not familiar with different types of containerization software, parallelization etc., just use singularity (I am doing the same)

`-bg` you can also remove this option, but then, the command stops if you close your command line

That's it – your first GWAS is running! How long does it take until you get your results? This depends on many parameters: the computational power of your server, the number of samples, the number of genotyped SNPs included in step 1 and the number of imputed SNPs included in step 2… it can take from a few hours to days (or weeks). If you use the command `htop`, it will display the current processes that are running (quit by typing in `q`).

If something is not working, nextflow will print an error on the command line. If everything works and your GWAS is finished you will find a folder called `output` in the directory of your configuration file. With FileZilla you can copy this folder onto your local computer. Within this folder, you will find the html report with the plots and summaries, the result files (whole summary statistics and the filtered annotated ones) and some other output files.

### What to do with errors

Before running the pipeline on your own data, you can run the pipeline with a small test dataset with the following command:
```
nextflow run genepi/gwas-regenie -c -r v0.1.13 -profile test,singularity -bg
```
(adapt the -r and -profile to the one you want to use on your data)

It should not take very long and you will get the outputs as described above for the test dataset. If this works, it means that you can execute the pipeline on your server, so if you get an error message when running the pipeline on your data, your input or configuration files have some issues. But even if this happens don't worry because the error message usually tells you which file has a problem or what you should do, just follow the instructions. If you are not sure, if your input files are formatted correctly, you can find some examples on the github repository: [https://github.com/genepi/gwas-regenie/tree/main/tests/input](https://github.com/genepi/gwas-regenie/tree/main/tests/input)

If you still cannot find a solution, post an issue on the github page, I am sure Lukas Forer and Sebastian Schoenherr (the developers of the pipeline) will find a solution :). If it's a non-pipeline related questions, the administrator hosting your server, another (bio)informatician you know, and also the internet in general is a great resource (e.g. you can ask questions in forums). Don't be afraid to ask!

There are two errors I came across, that are not formatting problems of your input files. If you have the same ones, here are the solutions:

- Error: `Cannot find revision 'v0.1.13'` -- Make sure that it exists in the remote repository `https://github.com/genepi/gwas-regenie`
-> This happens to me every time I use a new version of the pipeline. If the version exists on github, just re-run the same command, then it works
- Command error: `Failed to open --vcf file : Permission denied`
-> of course this could also happen for other files, it means that you don't have reading permission for these files. In this case you have to ask the administrator to give you reading permissions for these files. You can also check the permissions for a file by navigating to the folder and entering the `ls -l` command (the `-l` will list the files in the directory and on the left side it will display the permissions for each file)

## Conclusion

So to conclude, you don't need profound bioinformatics or command line knowledge to run your first GWAS. If I was able to do it, you can too :). In short, you only need:

1. Access to a Linux server, cluster or computer
2. A SSH client (e.g. Windows PowerShell) to navigate within the server and to execute commands
3. A multi-platform FTP client (e.g. FileZilla) to transfer files from your computer to the server and vice versa
4. The commands listed in Table 1 to navigate via the command line and to run your GWAS

## Table 1 - Command Line Tools to run your GWAS

| **Command** | **Description** | **Examples and additional infos** |
| --- | --- | --- |
| `pwd` | Will print your present working directory | |
| `ls` | Will print all files and directories within your present working directory | If you put a path (absolute or relative) after `ls` it will print the content of this directory) e.g. `ls /home` will print the content of the folder home; If you add `-l` it will print the files and directories in a list that contains additional information such as permissions |
| `mkdir` | Will make a new directory in your present working directory | `mkdir GWAS` will make a directory called `GWAS` |
| `cd` | Change directories | If you only enter `cd` without an absolute or relative path, it will change to your home directory; Entering `cd ..` will change your current directory to the parent folder; Entering `cd` with an absolute or relative path will change the directory to the respective folder |
| `nextflow run genepi/gwas-regenie -c <nextflow.config> -r v0.1.13 –profile singularity` | Will run the gwas pipeline; replace <nextflow.config> with the name of your configuration file; You can adapt the version of the pipeline by simply changing the version (v0.1.13) | Adding `-bg` will continue to run the pipeline even if you close the command line;Adding `-resume` will continue the pipeline with the files that have already been generated by a run of the same config file (e.g. if you only change the settings for the annotation files, it does not have to rerun the whole pipeline) |
| `htop` | Will display the current processes that are running | Hit `q` to quit |
| `vi` | A text editor in Linux that can display the content of a file, an alternative is for example `nano` (it can be used in the same way, but the advantage is that you can immediately start to modify the file) | E.g. enter `vi first-gwas.config` to view the content of the first-gwas.config file;To quit just type in the following command and hit enter `:q!`; After running a GWAS you might notice a `.nextflow.log` file in you folder when you check via FileZilla but you don't see them if you enter ls in the command line because the dot in the beginning of the file means its hidden. However, you can still look at the content of such a file by entering `vi .nextflow.log` |
