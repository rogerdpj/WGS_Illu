process FILTER {
  tag "FILTER: ${sample_id}"
  label 'env_filter' 

  publishDir "${params.outdir}/logs/filter", mode: 'copy', pattern: "*.txt"
  publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

  input:
  tuple val(sample_id), path(assembly_fasta)

  output:
  tuple val(sample_id), path("${sample_id}.filtered.fasta"), emit: assembly
  path "filter_stats_${sample_id}.txt", emit: stats
  path "${task.process}.version.txt", emit: versions

  script:
  
  """
  echo "seqtk\t\$(seqtk 2>&1 | grep -oE '[0-9]+\\.[0-9]+(-[a-zA-Z0-9]+)?' | head -n 1)" > ${task.process}.version.txt

  pre_counts=\$(grep -c '^>' ${assembly_fasta})
  pre_bases=\$(grep -v '^>' ${assembly_fasta} | tr -d '\\n' | wc -c)
  
  seqtk seq \
    -A \
    -L ${params.min_assembly_length} \
    ${assembly_fasta} \
    > ${sample_id}.filtered.fasta
  
  post_counts=\$(grep -c '^>' ${sample_id}.filtered.fasta)
  post_bases=\$(grep -v '^>' ${sample_id}.filtered.fasta | tr -d '\\n' | wc -c)
  
  cat << EOF > filter_stats_${sample_id}.txt
  Sample: ${sample_id}
  Sequences before : \$pre_counts
  Bases before   : \$pre_bases
  Sequences after  : \$post_counts
  Bases after    : \$post_bases
  Removed sequences: \$(( pre_counts - post_counts ))
  Removed bases  : \$(( pre_bases - post_bases ))
  EOF
  """
}