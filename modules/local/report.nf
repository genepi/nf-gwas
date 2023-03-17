process REPORT {

  label 'required_memory_report'

  input:
    tuple val(phenotype), path(regenie_merged), path(annotated_tophits)
    path phenotype_file_validated
    path gwas_report_template
    path r_functions_file
    path rmd_pheno_stats_file
    path rmd_valdiation_logs_file
    path phenotype_log
    path covariate_log
    path step1_log
    path step2_log

  output:
    tuple val(phenotype), path("${params.project}.${regenie_merged.baseName}.html"), emit: phenotype_report
    tuple val(phenotype), path("loci_${regenie_merged.baseName}.txt"), emit: phenotype_loci_n, optional: true
    path "${phenotype}.binned.txt"

  script:
      def annotation_as_string = params.manhattan_annotation_enabled.toString().toUpperCase()

  """
 java -jar /opt/gwas-report.jar report \
    ${regenie_merged} \
    --rsid RSID \
    --gene GENE_NAME \
    --annotation GENE \
    --peak-variant-Counting-pval-threshold ${params.annotation_min_log10p} \
    --peak-pval-threshold 1.5 \
    --format CSV \
    --binning BIN_TO_POINTS \
    --output ${phenotype}.binned.txt


  Rscript -e "require( 'rmarkdown' ); render('${gwas_report_template}',
    params = list(
      project = '${params.project}',
      date = '${params.project_date}',
      version = '$workflow.manifest.version',
      regenie_merged='${regenie_merged}',
      regenie_filename='${regenie_merged.baseName}',
      phenotype_file='${phenotype_file_validated}',
      phenotype='${phenotype}',
      covariates='${params.covariates_columns}',
      condition_list='${params.regenie_condition_list}',
      interaction_gxe='${params.regenie_interaction}',
      interaction_gxg='${params.regenie_interaction_snp}',
      phenotype_log='${phenotype_log}',
      covariate_log='${covariate_log}',
      regenie_step1_log='${step1_log}',
      regenie_step2_log='${step2_log}',
      plot_ylimit=${params.plot_ylimit},
      annotated_tophits_filename='${annotated_tophits}',
      manhattan_annotation_enabled = $annotation_as_string,
      annotation_min_log10p = ${params.annotation_min_log10p},
      r_functions='${r_functions_file}',
      rmd_pheno_stats='${rmd_pheno_stats_file}',
      rmd_valdiation_logs='${rmd_valdiation_logs_file}'
    ),
    intermediates_dir='\$PWD',
    knit_root_dir='\$PWD',
    output_file='\$PWD/${params.project}.${regenie_merged.baseName}.html'
  )"
  """
}
