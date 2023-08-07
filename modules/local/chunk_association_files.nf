process CHUNK_ASSOCIATION_FILES {

  input:
    tuple val(filename), path (bgen_file), path(bgen_index)
    val chunksize
    val strategy

  output:
    path "${bgen_file.baseName}_manifest.txt", emit: chunks

  """
  java -jar /opt/genomic-utils.jar bgen-chunk ${bgen_file} --out ${bgen_file.baseName}_manifest.txt --size ${chunksize} strategy ${strategy}
  """
  }
