FROM ubuntu:18.04
COPY environment.yml .

#  Install miniconda
RUN  apt-get update && apt-get install -y wget
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
  /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=/opt/conda/bin:${PATH}

RUN conda update -y conda
RUN conda env update -n root -f environment.yml

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

# Install regenie (not as conda package available)
WORKDIR "/opt"
RUN mkdir regenie && cd regenie && \
    wget https://github.com/rgcgithub/regenie/releases/download/v3.0/regenie_v3.0.gz_x86_64_Linux.zip && \
    unzip -q regenie_v3.*.gz_x86_64_Linux.zip && \
    rm regenie_v3.*.gz_x86_64_Linux.zip && \
    mv regenie_v3.*.gz_x86_64_Linux regenie && \
    chmod +x regenie
ENV PATH="/opt/regenie/:${PATH}"
