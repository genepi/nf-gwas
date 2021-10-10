process REPORT {

  publishDir "${params.outdir}", mode: 'copy'

  memory '5 GB'

  input:
    tuple val(phenotype), path(regenie_merged), path(annotated_tophits)
    path phenotype_file_validated
    path gwas_report_template
    path phenotype_log
    path covariate_log
    path step1_log
    path step2_log

  output:
    path "*.html"

  """
  Rscript -e "require( 'rmarkdown' ); render('${gwas_report_template}',
    params = list(
      project = '${params.project}',
      date = '${params.project_date}',
      version = '$workflow.manifest.version',
      regenie_merged='${regenie_merged}',
      regenie_filename='${regenie_merged.baseName}',
      phenotype_file='${phenotype_file_validated}',
      phenotype='${phenotype}',
      covariates='${params.covariates_columns.join(',')}',
      phenotype_log='${phenotype_log}',
      covariate_log='${covariate_log}',
      regenie_step1_log='${step1_log}',
      regenie_step2_log='${step2_log}',
      manhattan_plot_ylimit=${params.manhattan_plot_ylimit},
      annotated_tophits_filename='${annotated_tophits}'
    ),
    intermediates_dir='\$PWD',
    knit_root_dir='\$PWD',
    output_file='\$PWD/${params.project}.${regenie_merged.baseName}.html'
  )"
  """
}
