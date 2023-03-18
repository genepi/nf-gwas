process LIFTOVER_PREDICTION {

  input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file)
    path chain_file
  output:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file), emit:genotyped_plink_lifted_ch

  """
  # TODO: CHANGE TO HEADERLESS LIFTOVER. For now: add first line
  sed -i '1i CHROM\tID\tDUMMY_COLUMN\tGENPOS\tALLELE0\tALLELE1'  ${genotyped_plink_filename}.bim
  java -jar /opt/tabix-merge.jar liftover \
  --position GENPOS --alt ALLELE1 --chr CHROM --ref ALLELE0 \
  --chain ${chain_file} \
  --input ${genotyped_plink_filename}.bim --output ${genotyped_plink_filename}_updated.bim
  # TODO: CHANGE TO HEADERLESS LIFTOVER. For now: remove first line
  rm ${genotyped_plink_filename}.bim
  sed '1d' ${genotyped_plink_filename}_updated.bim > ${genotyped_plink_filename}.bim
  """

}
