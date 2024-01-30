import nextflow.Nextflow

class WorkflowMain {

    public static String citation(workflow) {
        return "If you use ${workflow.manifest.name} for your analysis please cite:\n\n" +
            "  https://www.biorxiv.org/content/10.1101/2023.08.08.552417v1"
    }

    public static void validate(params,genotypes_association_format){
    def ANSI_RESET = "\u001B[0m"
    def ANSI_YELLOW = "\u001B[33m"

    def requiredParams = [
        'project', 'phenotypes_filename','phenotypes_columns', 'phenotypes_binary_trait',
        'regenie_test'
    ]

    def requiredParamsGeneTests = [
        'project', 'phenotypes_filename', 'phenotypes_columns', 'phenotypes_binary_trait',
        'regenie_gene_anno', 'regenie_gene_setlist','regenie_gene_masks'
    ]

    for (param in requiredParams) {
        if (params[param] == null  && !params.regenie_run_gene_based_tests) {
        exit 1, "Parameter ${param} is required for single-variant testing."
    }
    }

     //check if all gene-based options are set
    for (param in requiredParamsGeneTests) {
        if (params[param] == null && params.regenie_run_gene_based_tests) {
            exit 1, "Parameter ${param} is required for gene-based testing."
        }
    }

    //check if all interaction options are set
    if(params.regenie_run_interaction_tests && (params["regenie_interaction"] == null && params["regenie_interaction_snp"] == null) ) {
        exit 1, "Parameter regenie_interaction or regenie_interaction_snp must be set."
    }

    if(!params.regenie_run_interaction_tests && (params["regenie_interaction"] != null || params["regenie_interaction_snp"] != null)){
        exit 1, "Interaction parameters are set but regenie_run_interaction_tests is set to false."
    }

    //check general parameters
    if(params["genotypes_association"] == null && params["genotypes_imputed"] == null ) {
        exit 1, "Parameter genotypes_association is required."
    }

    if(params["genotypes_association_format"] == null && params["genotypes_imputed_format"] == null ) {
        exit 1, "Parameter genotypes_association_format is required."
    }

    if(params["genotypes_array"] == null && params["genotypes_prediction"] == null && !params.regenie_skip_predictions ) {
        exit 1, "Parameter genotypes_prediction is required."
    }

    if(params["covariates_filename"] != null && (params.covariates_columns.isEmpty() && params.covariates_cat_columns.isEmpty())) {
        println ANSI_YELLOW +  "WARN: Option covariates_filename is set but no specific covariate columns (params: covariates_columns, covariates_cat_columns) are specified." + ANSI_RESET
    }

    if(params["genotypes_build"] == null && params["association_build"] == null ) {
        exit 1, "Parameter association_build is required."
    }

    if(params.rsids_filename == null) {
        println ANSI_YELLOW +  "WARN: A large rsID file will be downloaded for annotation. Please specify the path to the 'rsids_filename' parameter in the config (see docs for file creation) to avoid multiple downloads." + ANSI_RESET
    }

    if(params.genotypes_association_chunk_size > 0 && genotypes_association_format != 'bgen' ) {
        exit 1, " Chunking is currently only available for association files in bgen format (param: genotypes_association_chunk_size)."
    }

    if (params.regenie_run_gene_based_tests) {

        if (params.regenie_write_bed_masks && params.regenie_gene_build_mask == 'sum'){
            exit 1, "Invalid config file. The 'write-mask' option does not work when building masks with 'sum'."
        }

        if(params.genotypes_association_chunk_size > 0 ) {
            //&& genotypes_association_format != 'bgen' ) {
            exit 1, " Chunking is currently not available for gene-based tests (param: genotypes_association_chunk_size=0)."
        }

        //Check association file format for gene-based tests
        if (genotypes_association_format != 'vcf' && genotypes_association_format != "bgen"){
            exit 1, "File format " + genotypes_association_format + " currently not supported for gene-based tests. Please use 'vcf' or 'bgen' input instead. "
        }
        } else {
            //Check if tests exists
            if (params.regenie_test != 'additive' && params.regenie_test != 'recessive' && params.regenie_test != 'dominant'){
                exit 1, "Test ${params.regenie_test} not supported for single-variant testing."
            }

            //Check association file format
            if (genotypes_association_format != 'vcf' && genotypes_association_format != 'bgen'){
                exit 1, "File format " + genotypes_association_format + " not supported."
            }
        }    

    }
}