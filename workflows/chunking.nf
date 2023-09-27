include { CHUNK_ASSOCIATION_FILES     } from '../modules/local/chunking/chunk_association_files' 
include { COMBINE_MANIFEST_FILES      } from '../modules/local/chunking/combine_manifest_files' 


workflow CHUNKING {

    take:
    imputed_files
 
    main:
    chunk_size = params.genotypes_association_chunk_size
    strategy = params.genotypes_association_chunk_strategy

    if(chunk_size == 0) {

        //no conversion and chunking needed, set input to imputed_plink2_ch channel
        // -1 denotes that no range is applied
        imputed_files
            .map { tuple(it.baseName, it, [], [], -1) }
            .set {imputed_plink2_ch}

    } else {
        // chunking expects that a bgi file is available
        imputed_files
            .map {it -> tuple(it.baseName, it,file(it+".bgi", checkIfExists: true)) }
            .set {bgen_filepair}

        CHUNK_ASSOCIATION_FILES(bgen_filepair, chunk_size, strategy)

        COMBINE_MANIFEST_FILES(CHUNK_ASSOCIATION_FILES.out.chunks.collect())

        COMBINE_MANIFEST_FILES.out.combined_manifest
            .splitCsv(header:true, sep:',', quote: '\"')
            .map(row -> tuple(file(row["FILENAME"]).baseName,file(row["FILENAME"]),[],[],row["CONTIG"]+":" + row["START"] + "-" + row["END"]))
            .combine(bgen_filepair, by: 0)
            .map(row -> tuple(row[0], file(row[5]),file(row[6]),[],row[4]))
            .set {imputed_plink2_ch}

    }
       
    emit: 
    imputed_plink2_ch 
}


