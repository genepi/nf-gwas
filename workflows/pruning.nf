//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

include { PRUNE_GENOTYPED } from '../modules/local/prune_genotyped'

workflow PRUNING {

    take: genotyped_filtered_files_ch
    main:
    PRUNE_GENOTYPED (
        genotyped_filtered_files_ch
    )
    emit: 
    genotyped_final_ch = PRUNE_GENOTYPED.out.genotypes_pruned_ch

}


