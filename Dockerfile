#FROM nvidia/cuda:11.4.2-devel-ubuntu20.04 AS CUDA

FROM jupyter/r-notebook:6170f2394b18

ARG GITHUB_TOKEN
ENV GITHUB_TOKEN $GITHUB_TOKEN
ENV GITHUB_AUTH_MODE 'token'

USER root

# install packages that are nice for dev environment
RUN apt-get -qy update && apt-get install -qy \
    curl \
    gnupg \
    htop \
    less \
    libmysqlclient-dev \
    lsb-core \
    nano \
    openssh-client \
    gdb \
    vim \
    cmake \
    latexmk \
    libudunits2-dev \
    ocl-icd-opencl-dev
    #cython

# add gcp repo and install packages
ENV GCSFUSE_REPO gcsfuse-`lsb_release -c -s`
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-focal main" | tee /etc/apt/sources.list.d/gcsfuse.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get -qy update && apt-get install -qy \
    gcsfuse \
    google-cloud-sdk \
    kubectl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# always grant sudo since sometimes this is flakey when running on jhub
RUN echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook

USER $NB_USER

# bash improvements for developer environment
RUN git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it && \
    bash ~/.bash_it/install.sh --silent && \
    echo "export SCM_CHECK=false" >> /home/$NB_USER/.bashrc

RUN conda config --set channel_priority false

# this enables R to use mkl library
RUN conda install -c conda-forge --quiet --yes \
    'jupyterlab_latex' \
    'libblas=*=*_mkl' \
    'numexpr' \
    'numpy' \
    'python-language-server' \
    'r-languageserver' \
    'scikit-learn' \
    'scipy' \
    'pandas' \
    'seaborn' \
    #'xgboost' \
    'scikit-optimize' \
    'jupyter-lsp' \
    'ipywidgets' \
    'openpyxl' \
    'gcsfs' \
    'requests' \
    'pytest' \
    'spacy' \
    'pyarrow' \
    'fsspec' \
    'psycopg2' \
    'r-rasterVis' \
    #'cupy' \
    'jsonpickle' \
    #'xeus-python' \
    'jupyterlab_code_formatter' \
    'jupyterlab-git' \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR

RUN R -e "install.packages(c('googleCloudStorageR', 'corpus',  'Hmisc', 'caret', 'crayon', 'devtools', 'forecast', 'hexbin', 'htmltools', 'htmlwidgets', 'IRkernel', 'plyr', 'randomForest', 'curl', 'reshape2', 'rmarkdown', 'shiny', 'readr',  'RcppRoll', 'bigrquery', 'bit64', 'RestRserve', 'latex2exp', 'xgboost', 'rBayesianOptimization', 'ParBayesianOptimization', 'Metrics', 'formatR', 'hpiR', 'logging', 'shapr'), repo='http://cran.rstudio.com/')" && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

#RUN R -e "devtools::install_github('JuniperKernel/JuniperKernel')" && \
#    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN R -e "update.packages(ask = F, repos='http://cran.rstudio.com/')"

RUN pip install black \
    'google-cloud-bigquery[bqstorage,pandas]'

#RUN pip install 'jupyterlab-s3-browser'

RUN pip install cython \
    requests \
    shap \
    torch \
    hydra-core \
    pytorch_lightning \
    catalyst \
    transformers \
    timm \
    tables \
    datasets
    

#RUN pip install GPBoost

# install some additional jupyter lab extensions
RUN jupyter labextension install @ijmbarr/jupyterlab_spellchecker \
    @jupyterlab/latex \
    @krassowski/jupyterlab-lsp \
    @jupyter-widgets/jupyterlab-manager

ADD textbook-2.tar.gz /tmp/

RUN jupyter labextension install /tmp/Textbook 

RUN rm -rf /tmp/Textbook

#COPY --from=CUDA /usr/local/cuda-11.4 /usr/local

LABEL com.nvidia.volumes.needed="nvidia_driver"

ENV NVIDIA_VISIBLE_DEVICES "all"
ENV NVIDIA_DRIVER_CAPABILITIES "compute,utility"

USER root

RUN cd /tmp && \
    git clone --recursive https://github.com/microsoft/LightGBM.git && \
    cd LightGBM && \
    mkdir build && \
    cd build && \
    cmake -DUSE_GPU=1 .. && \
    make -j4 install && \
    cd .. && \
    Rscript build_r.R --use-gpu && \
    cd python-package && \
    python setup.py install && \
    cd /tmp && \
    rm -rf LightGBM

#RUN cd /tmp && \
#    git clone --recursive https://github.com/fabsig/GPBoost && \
#    cd GPBoost && \
#    mkdir build && \
#    cd build && \
#    cmake -DUSE_GPU=1 .. && \
#    make -j4 && \
#    cd .. && \
#    #Rscript build_r.R && \
#    cd python-package && \
#    python setup.py install && \
#    cd /tmp && \
#    rm -rf GPBoost    
  
ENV PATH $PATH::/usr/local/nvidia/lib64
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/nvidia/lib64


USER root 
RUN mkdir -p /etc/OpenCL/vendors
RUN echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

RUN cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    cd aws && \
    ./install && \
    cd /tmp && \
    rm -rf aws*

ENV PATH_BASE $PATH

#RUN conda create -c conda-forge -n transmo_dev -y python=3.8
#ENV PATH /opt/conda/envs/transmo_dev/bin:$PATH_BASE

#RUN cd /tmp && \
#    git clone "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/capeanalytics/transmo.git" --branch shane/dev && \
#    cd transmo && \
#    pip install . && \
#    pip install -r tests/test_requirements.txt && \
#    cd .. && \
#    rm -rf transmo

#RUN pip install "git+https://${GITHUB_TOKEN}:x-oauth-basic@github.com/capeanalytics/data_science_tools.git#egg=data_science_tools[mlops]"
#RUN pip install ipykernel 
#RUN python -m ipykernel install --name=transmo_dev    

ENV PATH $PATH_BASE

RUN cd /tmp && \
    git clone "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/capeanalytics/bedrock.git" && \
    cd bedrock && \
    conda env create -f monstrino/conda.yaml
    

ENV PATH /opt/conda/envs/monstrino/bin:$PATH_BASE

RUN cd /tmp && \
    cd bedrock && \
    pip install -r monstrino/tests/requirements.txt && \
    mkdir /bedrock && \
    cp -r monstrino /bedrock && \
    rm -rf /tmp/bedrock

RUN cd /tmp && \
    git clone "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/capeanalytics/transmo.git" && \
    cd transmo && \
    pip install . && \
    pip install -r tests/test_requirements.txt && \
    cd .. && \
    rm -rf transmo

RUN pip install "git+https://${GITHUB_TOKEN}:x-oauth-basic@github.com/capeanalytics/data_science_tools.git#egg=data_science_tools[mlops]"

RUN pip install ipykernel 

RUN python -m ipykernel install --name=monstrino

ENV PATH $PATH_BASE

RUN date >/build-date.txt

RUN conda init bash
