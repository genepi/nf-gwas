process DOWNLOAD_RSIDS {
  
  output:
  tuple  path("rsids-v154-hg${rsbuild}.index.gz"), path("rsids-v154-hg${rsbuild}.index.gz.tbi"), emit: rsids_ch

  script:
  def rsbuild = params.genotypes_build == 'hg19' ? "${19}" : "${38}"

  """
  #!/bin/bash
  if [ $rsbuild -eq 19 ]
  then
  wget https://resources.pheweb.org/rsids-v154-hg19.tsv.gz > rsids-v154-hg${rsbuild}.tsv.gz
  else
  wget https://resources.pheweb.org/rsids-v154-hg38.tsv.gz > rsids-v154-hg${rsbuild}.tsv.gz
  fi

  echo -e "CHROM\tPOS\tRSID\tREF\tALT" | bgzip -c > rsids-v154-hg${rsbuild}.index.gz
  zcat rsids-v154-hg${rsbuild}.tsv.gz | bgzip -c >> rsids-v154-hg${rsbuild}.index.gz
  tabix -s1 -b2 -e2 -S1 rsids-v154-hg${rsbuild}.index.gz

  """

}