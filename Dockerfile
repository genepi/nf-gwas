FROM continuumio/miniconda
MAINTAINER Lukas Forer <lukas.forer@i-med.ac.at>

COPY environment.yml .
RUN \
   conda env update -n root -f environment.yml \
&& conda clean -a

RUN apt-get update && apt-get install -y procps
