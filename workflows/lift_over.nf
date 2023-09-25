//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}
include { LIFTOVER_RESULTS } from '../modules/local/liftover_results.nf' 

workflow LIFT_OVER {

    take: 
    results_merged_regenie_only
    association_build
    main:
    target_build = params.target_build
    if(target_build != null && !association_build.equals(target_build)) {

        chain_file = file("$baseDir/files/chains/${association_build}To${target_build}.over.chain.gz", checkIfExists: true)

        LIFTOVER_RESULTS (
            results_merged_regenie_only,
            chain_file,
            target_build
        )

    }

}

