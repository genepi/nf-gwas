
nextflow.enable.dsl = 2

include { GWAS_REGENIE } from './workflows/gwas_regenie'

workflow {
    GWAS_REGENIE ()
}
