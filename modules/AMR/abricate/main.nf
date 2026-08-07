process ABRICATE {
    tag "ABRICATE: ${sample_id}"
    label 'env_abricate'
    
    publishDir "${params.outdir}/3-AMR/ABRICATE", mode: 'copy', pattern: "*.tsv"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(assembly_file), val(organism)

    output:
    path("${sample_id}_abricate_report.tsv"), emit: abricate_report
    tuple val(sample_id), path("${sample_id}_abricate_report.tsv"), emit: abricate_tuple
    path "${task.process}.version.txt", emit: versions

    script:

    // Convert organism name to lowercase and trim whitespace
    def organism_lc = organism.toLowerCase().trim()

    def amr_list = ["resfinder", "plasmidfinder", "card", "argannot"]
    def vf_list  = ["vfdb_full", "victors"]

    if (organism_lc.contains("ecoli") || organism_lc.contains("escherichia")) {
        vf_list = ["ecoli_vf"] + vf_list 
    }

    // Get databases for this organism or use default
    def amr_str = amr_list.collect { "\"${it}\"" }.join(" ")
    def vf_str  = vf_list.collect { "\"${it}\"" }.join(" ")

    def dbEnvBlock = params.abricate_db ? "export ABRICATE_DB='${params.abricate_db}'" : ""


    """
    echo -e "abricate\t\$(abricate --version 2>&1 | head -n 1 | awk '{print \$2}')" > ${task.process}.version.txt

    ${dbEnvBlock}

    AMR_DBS=(${amr_str})
    VF_DBS=(${vf_str})

    echo -e "FILE\tSEQUENCE\tSTART\tEND\tSTRAND\tGENE\tCOVERAGE\tCOVERAGE_MAP\tGAPS\t%COVERAGE\t%IDENTITY\tDATABASE\tACCESSION\tPRODUCT\tRESISTANCE\tTYPE\tORGANISM" > ${sample_id}_abricate_report.tsv

    for db in \${AMR_DBS[@]}; do
        echo "[AMR] Running ABRICATE with database: \$db"
        abricate --threads 4 --db \$db ${assembly_file} --noheader | \
        awk -v org="${organism}" '{print \$0"\\tAMR\\t"org}' \
        >> ${sample_id}_abricate_report.tsv
    done
    
    for db in \${VF_DBS[@]}; do
        echo "[VF] Running ABRICATE with database: \$db"
        abricate --threads 4 --db \$db ${assembly_file} --noheader | \
        awk -v org="${organism}" '{print \$0"\\tVF\\t"org}' \
        >> ${sample_id}_abricate_report.tsv
    done
    
    """
}