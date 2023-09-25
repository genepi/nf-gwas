class RegenieUtil {

    // extract phenotype name from regenie output file
    public static String getPhenotype(prefix, file ) {
        return file.baseName.replaceAll(prefix, '').split('_',2)[1].replaceAll('.regenie', '')
    }

    // extract phenotype name from regenie step1 chunk file
    public static String  getPhenotypeByChunk(prefix, file) {
        return file.baseName.replaceAll(prefix, '').split('_',3)[2].replaceAll('.regenie', '')
    }

}