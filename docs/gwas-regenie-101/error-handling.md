---
layout: page
title: "What to do with errors"
parent: Beginner Guide
nav_order: 4
---
## What to do with errors

Before running the pipeline on your own data, you can run the pipeline with a small test dataset with the following command:
```
nextflow run genepi/gwas-regenie -c -r v0.1.13 -profile test,singularity -bg
```
(adapt the -r and -profile to the one you want to use on your data)

It should not take very long and you will get the outputs as described above for the test dataset. If this works, it means that you can execute the pipeline on your server, so if you get an error message when running the pipeline on your data, your input or configuration files have some issues. But even if this happens don't worry because the error message usually tells you which file has a problem or what you should do, just follow the instructions. If you are not sure, if your input files are formatted correctly, you can find [some examples](https://github.com/genepi/gwas-regenie/tree/main/tests/configs) on the GitHub repository.

If you still cannot find a solution, post an issue on the GitHub page, I am sure Lukas Forer and Sebastian Schoenherr (the developers of the pipeline) will find a solution :). If it's a non-pipeline related questions, the administrator hosting your server, another (bio)informatician you know, and also the internet in general is a great resource (e.g. you can ask questions in forums). Don't be afraid to ask!

There are two errors I came across, that are not formatting problems of your input files. If you have the same ones, here are the solutions:

- Error: `Cannot find revision 'v0.1.13'` -- Make sure that it exists in the remote repository `https://github.com/genepi/gwas-regenie`
-> This happens to me every time I use a new version of the pipeline. If the version exists on GitHub, just re-run the same command, then it works
- Command error: `Failed to open --vcf file : Permission denied`
-> of course this could also happen for other files, it means that you don't have reading permission for these files. In this case you have to ask the administrator to give you reading permissions for these files. You can also check the permissions for a file by navigating to the folder and entering the `ls -l` command (the `-l` will list the files in the directory and on the left side it will display the permissions for each file)
