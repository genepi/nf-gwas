//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

include { QC_FILTER_GENOTYPED } from '../modules/local/qc_filter_genotyped' addParams(outdir: "$outdir")

workflow QUALITY_CONTROL {

    take: genotypes_prediction    
    main:
    Channel.fromFilePairs(genotypes_prediction, size: 3, checkIfExists: true).set {genotyped_plink_ch}

     QC_FILTER_GENOTYPED (
          genotyped_plink_ch
      )

    emit: 
    genotyped_filtered_files_ch = QC_FILTER_GENOTYPED.out.genotyped_filtered_files_ch
    genotyped_filtered_snplist_ch = QC_FILTER_GENOTYPED.out.genotyped_filtered_snplist_ch
    genotyped_filtered_id_ch = QC_FILTER_GENOTYPED.out.genotyped_filtered_id_ch

}


