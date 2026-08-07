process GENOME_MULTIQC {
    tag "GenomeQC report"
    label 'env_multiqc'

    publishDir "${params.outdir}/1-QC/genomeQC", mode: 'copy'
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    path qc_reports

    output:
    path "multiqc_report", emit: report
    path "${task.process}.version.txt", emit: versions

    script:

    """
    echo -e "multiqc\t\$(multiqc --version 2>&1 | awk '{print \$3}')" > ${task.process}.version.txt

    mkdir -p multiqc_input
    cp -r ${qc_reports} multiqc_input/ 2>/dev/null || true

    multiqc \
        multiqc_input/ \
        -o multiqc_report

    """
}