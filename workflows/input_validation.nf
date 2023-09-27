include { VALIDATE_PHENOTYPES } from '../modules/local/validate_phenotypes'
include { VALIDATE_COVARIATES } from '../modules/local/validate_covariates'

workflow INPUT_VALIDATION {

    main:
    phenotypes_file = file(params.phenotypes_filename, checkIfExists: true)
  
    VALIDATE_PHENOTYPES (
    phenotypes_file
    )

    covariates_file_validated_log = Channel.empty()
    covariates_file_validated = Channel.empty()

    if(params.covariates_filename) {
        covariates_file = file(params.covariates_filename, checkIfExists: true)

        VALIDATE_COVARIATES (
            covariates_file
        )

        covariates_file_validated = VALIDATE_COVARIATES.out.covariates_file_validated
        covariates_file_validated_log = VALIDATE_COVARIATES.out.covariates_file_validated_log

   } 

    emit: 
    phenotypes_file_validated = VALIDATE_PHENOTYPES.out.phenotypes_file_validated
    phenotypes_file_validated_log = VALIDATE_PHENOTYPES.out.phenotypes_file_validated_log
    covariates_file_validated
    covariates_file_validated_log 
}


