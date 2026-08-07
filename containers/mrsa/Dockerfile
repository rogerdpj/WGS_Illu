FROM mambaorg/micromamba:1.5.7
LABEL authors="ROGER DE PEDRO JOVE" \
      description="Docker image containing the environment with all the tools for MRSA typing"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Create environment
RUN micromamba create -n assembly_env -y \
    -c bioconda -c conda-forge \
    spaTyper=0.3.3 \
    sccmec=1.2.0 \
    && micromamba clean --all --yes

# Activate environment
ENV PATH=/opt/conda/envs/assembly_env/bin:$PATH

# Default shell
SHELL ["/bin/bash", "-c"]