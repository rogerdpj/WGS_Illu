process PREPARE_KRAKEN_DB {
  tag "${params.db_select ?: 'db_16GB'}"
  label 'env_kraken_db'

  containerOptions = params.db_bind ? "--bind ${params.db_bind}" : null

  cpus 2
  memory '4 GB'
  time '24h'

  output:
  path 'kraken_db', emit: db_ready

  script:

  """
  export DB_DIR="/kraken2-db"
  export DB_SELECT='${params.db_select}'

  mkdir -p "\$DB_DIR"

  
  if [ -f "\$DB_DIR/\$DB_SELECT/hash.k2d" ]; then
      echo "Kraken DB already exists → skipping download"
  else
      echo "Kraken DB not found → downloading"
      ${ params.db_url ? "export DB_URL='${params.db_url}'" : ":" }
      ${ params.db_url_checksum ? "export DB_URL_CHECKSUM='${params.db_url_checksum}'" : ":" }
      kraken2-entrypoint.sh prepare-db "\$DB_SELECT"
  fi
  
  chmod -R a+rX "\$DB_DIR" || true

  mkdir -p kraken_db
  cp -rs "\$DB_DIR/\$DB_SELECT"/. kraken_db/
  
  """
}