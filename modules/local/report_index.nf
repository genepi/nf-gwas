import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

process REPORT_INDEX {

  publishDir "${params.outdir}", mode: 'copy'

  label 'required_memory_report'

  input:
    val phenotype_tuples

  output:
    path "index.html"
    path "index_reports/*"

  script:
    phenotypes = []
    files = []
    reports = []
    for (phenotype_tuple: phenotype_tuples){
      phenotypes.push(phenotype_tuple[0])
      files.push(phenotype_tuple[1])
      reports.push(phenotype_tuple[2])
    }

  """
  java -jar /opt/gwas-report.jar report \
    ${files.join(" ")} \
    --rsid RSID \
    --gene GENE_NAME \
    --annotation GENE \
    --tab-name "Details and Phenotype" \
    --tab-links "${reports.join(",")}" \
    --names "${phenotypes.join(",")}" \
    --title "${params.project}" \
    --peak-variant-Counting-pval-threshold ${params.annotation_min_log10p} \
    --peak-pval-threshold 1.5 \
    --output index.html
  """
}
