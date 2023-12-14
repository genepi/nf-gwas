process IMPUTED_TO_PLINK2 {

    input:
    path imputed_vcf_file
    // TODO: Replace -1 with range 
    output:
    tuple val("${imputed_vcf_file.baseName}"), path("${imputed_vcf_file.baseName}.pgen"), path("${imputed_vcf_file.baseName}.psam"),path("${imputed_vcf_file.baseName}.pvar"), val(-1), emit: imputed_plink2

    script:
    def delimiter = params.vcf_conversion_split_id  ? "--id-delim" : '--double-id'
    """
    plink2 \
        --vcf $imputed_vcf_file dosage=DS \
        --make-pgen \
        $delimiter \
        --out ${imputed_vcf_file.baseName} \
        --threads ${task.cpus} \
        --memory ${task.memory.toMega()}
    """
}
