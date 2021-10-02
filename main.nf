#!/usr/bin/env nextflow
/*
========================================================================================
    genepi/gwas-regenie
========================================================================================
    Github : https://github.com/genepi/gwas-regenie
    Author: Sebastian Schönherr & Lukas Forer
    ---------------------------
*/

nextflow.enable.dsl = 2

include { GWAS_REGENIE } from './workflows/gwas_regenie'

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

workflow {
    GWAS_REGENIE ()
}
