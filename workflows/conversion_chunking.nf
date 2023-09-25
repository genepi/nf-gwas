//TODO duplicate code
if(params.outdir == null) {
    outdir = "output/${params.project}"
} else {
    outdir = params.outdir
}

include { IMPUTED_TO_PLINK2 } from '../modules/local/imputed_to_plink2' addParams(outdir: "$outdir")

workflow CONVERSION_CHUNKING {

    take:
    genotypes_association
    genotypes_association_format
    main:
    imputed_files =  channel.fromPath(genotypes_association, checkIfExists: true)

    if (genotypes_association_format == "vcf"){

        //TODO: add VCF chunking
        IMPUTED_TO_PLINK2 (
             imputed_files
        )

        imputed_plink2_ch = IMPUTED_TO_PLINK2.out.imputed_plink2


    } else {
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

  
    }
    
    emit: 
    imputed_plink2_ch = IMPUTED_TO_PLINK2.out.imputed_plink2
}


