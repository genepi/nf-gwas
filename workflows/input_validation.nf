//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

include { VALIDATE_PHENOTYPES } from '../modules/local/validate_phenotypes'
include { VALIDATE_COVARIATES } from '../modules/local/validate_covariates'

workflow INPUT_VALIDATION {

    main:
    phenotypes_file = file(params.phenotypes_filename, checkIfExists: true)
    if (!params.covariates_filename) {
        covariates_file = []
        } else {
        covariates_file = file(params.covariates_filename, checkIfExists: true)
    }

    VALIDATE_PHENOTYPES (
    phenotypes_file
    )

    covariates_file_validated_log = Channel.empty()
    if(params.covariates_filename) {
        VALIDATE_COVARIATES (
          covariates_file
        )

        covariates_file_validated = VALIDATE_COVARIATES.out.covariates_file_validated
        covariates_file_validated_log = VALIDATE_COVARIATES.out.covariates_file_validated_log

   } else {

        // set covariates_file to default value
        covariates_file_validated = covariates_file

   }

    emit: 
    phenotypes_file_validated = VALIDATE_PHENOTYPES.out.phenotypes_file_validated
    phenotypes_file_validated_log = VALIDATE_PHENOTYPES.out.phenotypes_file_validated_log
    covariates_file_validated
    covariates_file_validated_log 

}


