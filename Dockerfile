# 1. 기반 이미지 설정
FROM rocker/tidyverse:4.4.0

# 2. 시스템 의존성 설치 (ImageMagick 포함)
USER root
RUN apt-get update && apt-get install -y \
    wget \
    git \
    imagemagick \
    libmagick++-dev \
    libzmq3-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 3. Miniconda 설치
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 4. Conda 경로 설정 및 환경 생성
ENV PATH=$CONDA_DIR/bin:$PATH

RUN conda config --set auto_activate_base false && \
    conda create -n r-reticulate -c conda-forge --override-channels python=3.12 \
    jupyter pip numpy pandas polars plotnine statsmodels mizani scipy plotly -y && \
    conda clean -afy

# ✨ 추가된 부분: 도커 빌드 시에도 가상환경 내부에 pip 패키지 설치
RUN conda run -n r-reticulate pip install pybabynames pylahman

ENV PATH=/opt/conda/envs/r-reticulate/bin:$PATH

# 5. R 패키지 설치 (reticulate 및 필수 패키지)
RUN R -e "install.packages(c('reticulate', 'remotes', 'IRkernel', 'knitr', 'rmarkdown', 'dplyr', 'babynames', 'mdsr', 'Lahman', 'tidyr', 'ggplot2', 'patchwork', 'NHANES', 'tidyverse', 'ggtext', 'mosaicData', 'gridExtra', 'boot', 'tibble', 'car', 'MASS'))" && \
    R -e "IRkernel::installspec(user = FALSE)"

# 6. reticulate가 사용할 Python 경로 고정 (환경 변수)
ENV RETICULATE_PYTHON=/opt/conda/envs/r-reticulate/bin/python

# 7. (선택) Binder 사용자를 위한 권한 설정
# Binder는 보통 'jovyan' 유저 권한으로 실행
RUN chown -R ${NB_USER:-root} /opt/conda

# 기본 실행 경로 설정
WORKDIR /home/rstudio