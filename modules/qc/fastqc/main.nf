//Quality analisis 
process FASTQC {
    tag "QC: ${reads.name}"
    label 'env_fastqc'

    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    path (reads)

    output:
    path ("*.html"), emit: qc_html
    path ("*.zip"), emit: qc_zip
    path "${task.process}.version.txt", emit: versions

    script:
    """
    echo "fastQC\t\$(fastqc --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+(\\.[0-9]+)?' | head -n 1)" > ${task.process}.version.txt

    fastqc \
        --threads ${task.cpus} \
        ${reads}
    """
}