FROM ubuntu:22.04
COPY environment.yml .

#  Install miniconda
RUN  apt-get update && apt-get install -y wget
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py39_23.9.0-0-Linux-x86_64.sh -O ~/miniconda.sh && \
  /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=/opt/conda/bin:${PATH}

RUN conda update -y conda && \
    conda env update -n root -f environment.yml && \
    conda clean --all

# Install software
RUN apt-get update && \
    apt-get install -y gfortran \
    python3 \
    zlib1g-dev \
    libgomp1 \
    procps \
    libx11-6
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install jbang (not as conda package available)
WORKDIR "/opt"
RUN wget https://github.com/jbangdev/jbang/releases/download/v0.91.0/jbang-0.91.0.zip && \
    unzip -q jbang-*.zip && \
    mv jbang-0.91.0 jbang  && \
    rm jbang*.zip

ENV PATH="/opt/jbang/bin:${PATH}"

# Install genomic-utils
WORKDIR "/opt"
ENV GENOMIC_UTILS_VERSION="v0.3.7"
RUN wget https://github.com/genepi/genomic-utils/releases/download/${GENOMIC_UTILS_VERSION}/genomic-utils.jar

ENV JAVA_TOOL_OPTIONS="-Djdk.lang.Process.launchMechanism=vfork"

COPY ./bin/RegenieLogParser.java ./
RUN jbang export portable --verbose -O=RegenieLogParser.jar RegenieLogParser.java

COPY ./bin/RegenieValidateInput.java ./
RUN jbang export portable -O=RegenieValidateInput.jar RegenieValidateInput.java

# Install regenie (not as conda package available)
WORKDIR "/opt"
ENV REGENIE_VERSION="v3.4"
RUN mkdir regenie && cd regenie && \
    wget https://github.com/rgcgithub/regenie/releases/download/${REGENIE_VERSION}/regenie_${REGENIE_VERSION}.gz_x86_64_Linux.zip && \
    unzip -q regenie_${REGENIE_VERSION}.gz_x86_64_Linux.zip && \
    rm regenie_${REGENIE_VERSION}.gz_x86_64_Linux.zip && \
    mv regenie_${REGENIE_VERSION}.gz_x86_64_Linux regenie && \
    chmod +x regenie

ENV PATH="/opt/regenie/:${PATH}"