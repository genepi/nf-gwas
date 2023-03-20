process LIFTOVER_RESULTS {

  publishDir "${params.outdir}/results", mode: 'copy'

  input:
    path regenie_file
    file chain_file
    val hg_build_target

  output:
    path "${regenie_file.baseName}_${hg_build_target}.gz*"

  """
  java -jar /opt/genomic-utils.jar liftover \
  --position GENPOS --alt ALLELE1 --chr CHROM --ref ALLELE0 \
  --chain ${chain_file} \
  --input ${regenie_file} --output ${regenie_file.baseName}_${hg_build_target}
  bgzip ${regenie_file.baseName}_${hg_build_target}
  tabix -f -b 2 -e 2 -s 1 -S 1 ${regenie_file.baseName}_${hg_build_target}.gz
  """

}
