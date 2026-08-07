process MULTIQC {
    tag "FastQC report"
    label 'env_multiqc'

    publishDir "${params.outdir}/1-QC/fastqQC", mode: 'copy'
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    path fastqc_first
    path fastqc_after

    output:
    path "multiqc_report", emit: report
    path "${task.process}.version.txt", emit: versions

    script:
    """
    echo -e "multiqc\t\$(multiqc --version 2>&1 | awk '{print \$3}')" > ${task.process}.version.txt

    echo "FastQC files: ${fastqc_first} ${fastqc_after}"

    multiqc ${fastqc_first} ${fastqc_after} -o multiqc_report
    """
}