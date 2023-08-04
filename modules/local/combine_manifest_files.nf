process COMBINE_MANIFEST_FILES {

  input:
    path input

  output:
    path "combined_manifest.txt", emit: combined_manifest

  """
  csvtk concat ${input} > combined_manifest.txt
  """
  }
