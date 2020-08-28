FROM jupyter/r-notebook:5197709e9f23

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
    vim

# add gcp repo and install packages
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-$(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gcsfuse.list && \
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

# this enables R to use mkl library
RUN conda install -c conda-forge --quiet --yes \
    'jupyterlab_latex' \
    'libblas=3.8.0=14_mkl' \
    'numexpr=2.7.*' \
    'numpy=1.18.*' \
    'python-language-server' \
    'r-languageserver' \
    'scikit-learn=0.22.*' \
    'scipy=1.4.*' \
    'jupyterlab_latex' \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR

RUN R -e "install.packages(c('Hmisc', 'rasterVis', 'caret', 'crayon', 'devtools', 'forecast', 'hexbin', 'htmltools', 'htmlwidgets', 'IRkernel', 'plyr', 'randomForest', 'curl', 'reshape2', 'rmarkdown', 'shiny', 'readr',  'RcppRoll', 'bigrquery', 'bit64', 'RMySQL', 'RestRserve', 'latex2exp'), repo='http://cran.rstudio.com/')" && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# install some additional jupyter lab extensions
RUN jupyter labextension install @ijmbarr/jupyterlab_spellchecker \
    @jupyterlab/latex \
    @krassowski/jupyterlab-lsp

COPY files/mount-gcsfuse.sh /usr/local/bin
