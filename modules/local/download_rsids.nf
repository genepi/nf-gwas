process DOWNLOAD_RSIDS {

  output:
  tuple  path("rsids-v154-${rsbuild}.index.gz"), path("rsids-v154-${rsbuild}.index.gz.tbi"), emit: rsids_ch

  script:
  def rsbuild = params.genotypes_build

  """
  wget https://resources.pheweb.org/rsids-v154-${rsbuild}.tsv.gz -O rsids-v154-${rsbuild}.tsv.gz
  echo -e "CHROM\tPOS\tRSID\tREF\tALT" | bgzip -c > rsids-v154-${rsbuild}.index.gz
  zcat rsids-v154-${rsbuild}.tsv.gz | bgzip -c >> rsids-v154-${rsbuild}.index.gz
  tabix -s1 -b2 -e2 -S1 rsids-v154-${rsbuild}.index.gz

  """

}
