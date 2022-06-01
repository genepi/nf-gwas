#!/usr/bin/env nextflow
/*
========================================================================================
    genepi/nf-gwas
========================================================================================
    Github : https://github.com/genepi/nf-gwas
    Author: Sebastian Schönherr & Lukas Forer
    ---------------------------
*/

nextflow.enable.dsl = 2

include { NF_GWAS_GENE } from './workflows/nf_gwas_gene'

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

workflow {
    NF_GWAS_GENE ()
}
