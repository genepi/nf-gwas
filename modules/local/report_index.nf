import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

process REPORT_INDEX {

  publishDir "${params.outdir}", mode: 'copy'

  label 'required_memory_report'

  input:
    val phenotype_tuples

  output:
    path "index.html"

  script:
    phenotypes = []
    files = []
    for (phenotype_tuple: phenotype_tuples){
      phenotypes.push(phenotype_tuple[0])
      files.push(phenotype_tuple[1].name)
    }

  """

  bash report.sh \
    --phenotypes "${phenotypes.join(",")}" \
    --files "${files.join(",")}" \
    --project "${params.project}" \
    --version "$workflow.manifest.version" \
    --output index.html
  """
}
