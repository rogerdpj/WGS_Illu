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
  echo "seqtk\t\$(seqtkit 2>&1 | grep -oE '[0-9]+\\.[0-9]+(-[a-zA-Z0-9]+)?' | head -n 1)" > ${task.process}.version.txt

  pre_counts=\$(grep -c '^>' ${assembly_fasta})
  pre_bases=\$(seqkit stats -T ${assembly_fasta} | awk 'NR==2 {print \$5}')
  
  grep '^>' ${assembly_fasta} | awk -v min_cov="${params.min_assembly_coverage}" '
  {
      for (i=1; i<=NF; i++) {
          if (\$i ~ /cov_/) {
              split(\$i, a, "cov_");
              split(a[2], b, "_");
              if (b[1] + 0 >= min_cov + 0) {
                  sub(/^>/, "", \$1);
                  print \$1;
              }
          }
      }
  }' > valid_cov_ids.txt

  seqkit grep -f valid_cov_ids.txt ${assembly_fasta} | \
  seqkit seq -m ${params.min_assembly_length} > ${sample_id}.filtered.fasta

  post_counts=\$(grep -c '^>' ${sample_id}.filtered.fasta)
  post_bases=\$(seqkit stats -T ${sample_id}.filtered.fasta | awk 'NR==2 {print \$5}')

  cat << EOF > filter_stats_${sample_id}.txt
  Sample: ${sample_id}
  Min Length Cutoff  : ${params.min_assembly_length} bp
  Min Coverage Cutoff: ${params.min_assembly_coverage}x
  Sequences before : \$pre_counts
  Bases before   : \$pre_bases
  Sequences after  : \$post_counts
  Bases after    : \$post_bases
  Removed sequences: \$(( pre_counts - post_counts ))
  Removed bases  : \$(( pre_bases - post_bases ))
  EOF
  """
}