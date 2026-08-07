FROM mambaorg/micromamba:1.5.7
LABEL authors="ROGER DE PEDRO JOVE" \
      description="Docker image containing the environment with all the tools for assembling/polishing Illumina data"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Create environment
RUN micromamba create -n assembly_env -y \
    -c bioconda -c conda-forge \
    gzip \
    coreutils \
    bwa=0.7.19 \
    samtools=1.24 \
    && micromamba clean --all --yes

# Activate environment
ENV PATH=/opt/conda/envs/assembly_env/bin:$PATH

# Default shell
SHELL ["/bin/bash", "-c"]