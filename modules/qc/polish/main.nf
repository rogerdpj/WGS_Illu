process ALIGNMENT_PILON {
  tag "Alignment: ${sample_id}"
  label 'env_alignment'

  publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"
  publishDir "${params.outdir}/logs/alignment", mode: 'copy', pattern: "*.stats.txt"

  input:
  tuple val(sample_id), path(filtered_fasta), path(reads)

  output:
  tuple val(sample_id), path("${sample_id}.bwa.aln.sorted.bam"), emit: aln_bam
  tuple val(sample_id), path("${sample_id}.bwa.aln.sorted.bam.bai"), emit: aln_bai
  path("${sample_id}.bwa.aln.sorted.bam.stats.txt"), emit: aln_stats
  path "${task.process}.version.txt", emit: versions

  script:
  """
  echo "bwa\t\$(bwa 2>&1 | grep Version | awk '{print \$2}')" > ${task.process}.version.txt
  echo "samtools\t\$(samtools --version | head -n1 | awk '{print \$2}')" >> ${task.process}.version.txt
  
  bwa index ${filtered_fasta}

  bwa mem \
    -t ${task.cpus} \
    ${filtered_fasta} \
    ${reads[0]} \
    ${reads[1]} \
    | samtools sort -O BAM -o ${sample_id}.bwa.aln.sorted.bam

  samtools index ${sample_id}.bwa.aln.sorted.bam

  samtools flagstat ${sample_id}.bwa.aln.sorted.bam > ${sample_id}.bwa.aln.sorted.bam.stats.txt
  samtools idxstats ${sample_id}.bwa.aln.sorted.bam >> ${sample_id}.bwa.aln.sorted.bam.stats.txt
  
  """
}

process PILON_POLISH {
  tag   "Pilon: ${sample_id}"
  label 'env_pilon'

  publishDir "${params.outdir}/2-Assembly/", mode: 'copy', pattern: '*.pilon.changes.txt'
  publishDir "${params.outdir}/2-Assembly/", mode: 'copy', pattern: '*.fasta'
  publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"
  publishDir "${params.outdir}/logs/pilon", mode: 'copy', pattern: "*.changes.txt"
  publishDir "${params.outdir}/logs/pilon", mode: 'copy', pattern: "*.variants.vcf"


  input:
  tuple val(sample_id), path(filtered_fasta), path(index_bam)

  output:
  tuple val(sample_id), path("${sample_id}.fasta"), emit: pilon_fa
  path "${sample_id}.pilon.changes.txt", emit: info_pilon_changes
  path "${sample_id}.pilon.variants.vcf", emit: variants
  path "${task.process}.version.txt", emit: versions

  script:
  """
  echo "pilon\t\$(java -jar /pilon/pilon.jar --version 2>&1 | grep Version | awk '{print \$2}')" > ${task.process}.version.txt

  java -Xmx${task.memory.toGiga()}g \
       -jar /pilon/pilon.jar \
       --genome ${filtered_fasta} \
       --frags ${index_bam} \
       --output pilon \
       --threads ${task.cpus} \
       --changes \
       --vcf \
       --tracks

  # Move and save stats results
  mv pilon.fasta ${sample_id}.fasta
  mv pilon.changes ${sample_id}.pilon.changes.txt
  mv pilon.vcf ${sample_id}.pilon.variants.vcf

  """
}