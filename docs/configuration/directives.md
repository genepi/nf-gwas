---
layout: page
title: Directives
parent: Configuration
nav_order: 2
---

## Directives
Depending on your actual server or cluster, the memory and CPU directives must be adapted to run all processes as efficient as possible. Please find below the default setting. Copy/paste the process section to your configuration file and run your GWAS. Read also [here](https://rgcgithub.github.io/regenie/performance/) to learn about memory requirements of regenie.

```
process {

    withLabel: 'process_plink2' {
        cpus   =  4
        memory =  32.GB
    }

    withLabel: 'required_memory_report' {
        memory =  32.GB
    }

    //recommend to run regenie using multi-threading (8+ threads)
    withName: 'REGENIE_STEP1|REGENIE_STEP2'
    {
        cpus   = 8
        memory = 16.GB
    }

}
```
