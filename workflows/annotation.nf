//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}
include { DOWNLOAD_RSIDS   } from '../modules/local/download_rsids.nf' 
include { ANNOTATE_RESULTS } from '../modules/local/annotate_results' 
workflow ANNOTATION {

    take: 
    regenie_step2_out
    association_build

    main:

    //Annotation files
genes_hg19 = file("$baseDir/genes/genes.hg19.v32.csv", checkIfExists: true)
genes_hg38 = file("$baseDir/genes/genes.hg38.v32.csv", checkIfExists: true)

//Optional rsids annotation file and _tbi file
rsids = params.rsids_filename
if (rsids != null) {
  rsids_file = file(rsids, checkIfExists: true)
  rsids_tbi_file = file(rsids+".tbi", checkIfExists: true)
} else {
  println ANSI_YELLOW+  "WARN: A large rsID file will be downloaded for annotation. Please specify in config to avoid download." + ANSI_RESET

}
    
    if(rsids == null) {
        DOWNLOAD_RSIDS(association_build)
        annotation_files =  DOWNLOAD_RSIDS.out.rsids_ch
        } else {
             annotation_files = tuple(rsids_file, rsids_tbi_file)
        }

    ANNOTATE_RESULTS (
        regenie_step2_out,
        genes_hg19,
        genes_hg38,
        annotation_files,
        association_build
    )

    // for default step2 annotation are splitting into seperate phenotypes files after annotation
    ANNOTATE_RESULTS.out.annotated_ch
        .transpose()
        .map { prefix, fl -> tuple(RegenieUtil.getPhenotype(prefix, fl), fl) }
        .set { regenie_step2_by_phenotype }
   
    emit: 
    regenie_step2_by_phenotype
    
}

