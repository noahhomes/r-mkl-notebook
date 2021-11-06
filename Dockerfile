FROM jupyter/r-notebook:7aa954ab78d1
#5211732116f7
#7e07b801d92b
#399cbb986c6b

USER root

# install packages that are nice for dev environment
RUN apt-get -qy update && apt-get install -qy \
    curl \
    gnupg \
    htop \
    less \
    libmysqlclient-dev \
    postgresql-client \
    libssl-dev \
    libpq-dev \
    lsb-core \
    nano \
    openssh-client \
    gdb \
    vim \
    cmake \
    graphviz \
    latexmk

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


#RUN conda config --add channels conda-forge

#RUN conda config --remove channels conda-forge
RUN conda config --set channel_priority flexible

# this enables R to use mkl library
RUN conda install --no-channel-priority -c conda-forge --quiet --yes \
    'jupyterlab_latex' \
    'libblas' \
    'numexpr' \
    'numpy' \
    'python-language-server' \
    'r-languageserver' \
    'scikit-learn' \
    'scipy' \
    'pandas' \
    'seaborn' \
    'xgboost' \
    'scikit-optimize' \
    'jupyter-lsp' \
    'ipywidgets' \
    'openpyxl' \
    'gcsfs' \
    'pyarrow' \
    'fsspec' \
    'psycopg2' \
    'parse' \
    'r-rastervis' \
    'r-hmisc' \
    'r-juniperkernel' \
    'xeus-python' \
    'jupyterlab_code_formatter' \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR

# install some additional jupyter lab extensions
RUN jupyter labextension install @ijmbarr/jupyterlab_spellchecker \
    @jupyterlab/latex \
    #@joequant/jupyterlab-latex \
    @krassowski/jupyterlab-lsp \
    @jupyter-widgets/jupyterlab-manager

RUN R -e "install.packages(c( 'caret', 'crayon', 'devtools', 'forecast', 'hexbin', 'htmltools', 'htmlwidgets', 'IRkernel', 'plyr', 'randomForest', 'curl', 'reshape2', 'rmarkdown', 'shiny', 'readr',  'RcppRoll', 'bigrquery', 'bit64', 'RMySQL', 'RestRserve', 'latex2exp', 'xgboost', 'rBayesianOptimization', 'ParBayesianOptimization', 'Metrics', 'RPostgreSQL', 'formatR'), repo='http://cran.rstudio.com/')" && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN R -e "update.packages(ask = F, repo='http://cran.rstudio.com/')"

RUN R -e 'devtools::install_github("JuniperKernel/JuniperKernel")'

RUN cd /tmp && \
    git clone --recursive https://github.com/microsoft/LightGBM.git && \
    cd LightGBM && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j4 && \
    cd .. && \
    Rscript build_r.R && \
    cd python-package && \
    python setup.py install && \
    cd /tmp && \
    rm -rf LightGBM


COPY files/mount-gcsfuse.sh /usr/local/bin


USER root
ADD textbook.tar.gz /tmp

RUN jupyter labextension install /tmp/Textbook

RUN rm -rf /tmp/textbook

USER $NB_USER