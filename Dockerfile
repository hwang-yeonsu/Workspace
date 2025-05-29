# syntax=docker/dockerfile:1.4

# ==================================================================
# Stage 1: Common Base - 공통 기본 환경 (Python, uv, 기본 개발 도구)
# ------------------------------------------------------------------
FROM python:3.11.7 as common-base

# 기본 환경 변수 설정
ENV LANG C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_VENV_DIR=/opt/venv

# 시스템 업데이트 및 개발에 필요한 공통 도구 설치
# (git, htop, vim, curl, fd-find, ca-certificates, wget, apt-utils, libssl-dev 등)
RUN rm -f /etc/apt/sources.list.d/cuda.list /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-utils \
        ca-certificates \
        wget \
        curl \
        git \
        vim \
        htop \
        fd-find \
        libssl-dev \
        bash-completion \
        # uv 설치를 위한 pip (uv 설치 후 pip 제거)
        python3-pip \
    && ln -s $(which fdfind) /usr/local/bin/fd \
    && pip install --no-cache-dir uv \
    && apt-get purge -y --auto-remove python3-pip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# uv 가상 환경 생성 및 의존성 설치
RUN echo "Creating uv virtual environment in ${UV_VENV_DIR}" && \
    uv venv ${UV_VENV_DIR} --python $(which python)

WORKDIR /app


# ==================================================================
# Stage 2: Builder - Python 의존성 빌드 및 애플리케이션 코드 준비
# ------------------------------------------------------------------
FROM common-base as builder
# common-base에서 WORKDIR /app 상속

# Python 패키지 빌드에 필요할 수 있는 추가 도구 (예: C 확장 컴파일)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        unzip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# uv 캐시 디렉토리 환경 변수 설정
# 도커 자체적으로 관리하는 캐시 디렉토리이며 명시적으로 삭제할 수 있음
# docker builder prune, docker system prune
ENV UV_CACHE_DIR=/root/.cache/uv

COPY .jupyter /root/.jupyter

# 의존성 파일 복사
# pyproject.toml과 uv.lock을 사용한다면 해당 파일들을 복사하세요.
COPY requirements.txt .

# (Optional) 생성된 가상 환경에 패키지 설치 (시스템 uv 사용 및 --python 옵션으로 가상 환경 Python 지정)
RUN --mount=type=cache,target=${UV_CACHE_DIR} \
    echo "Installing dependencies into ${UV_VENV_DIR} using global uv and targeting venv python..." && \
    uv pip install --python ${UV_VENV_DIR}/bin/python -r requirements.txt && \
    echo "Python dependencies installed into ${UV_VENV_DIR}."

# # 애플리케이션 소스 코드 복사 및 처리  ##!!
# COPY . .


# ==================================================================
# Stage 3: Final - 최종 개발 환경 (모든 개발 도구 및 애플리케이션 포함)
# ------------------------------------------------------------------
# common-base에서 WORKDIR /app 및 개발 도구들 상속
FROM common-base as final

# Builder 스테이지에서 생성된 가상 환경 복사
COPY --from=builder ${UV_VENV_DIR} ${UV_VENV_DIR}

# Builder 스테이지에서 복사된 애플리케이션 코드 복사
COPY --from=builder /root/.jupyter /root/.jupyter
COPY --from=builder /app /app

# uv 가상 환경 사용을 위한 환경 변수 설정
ENV VIRTUAL_ENV=${UV_VENV_DIR}
ENV PATH="${UV_VENV_DIR}/bin:$PATH"

RUN git config --global --add safe.directory '*'
RUN echo '\n# Source bash completion script\n. /usr/share/bash-completion/bash_completion' >> /root/.bashrc

# (Optional) Non-privileged user 설정
# ARG UID=10001
# RUN adduser \
#     --disabled-password \
#     --gecos "" \
#     --home "/nonexistent" \
#     --shell "/sbin/nologin" \
#     --no-create-home \
#     --uid "${UID}" \
#     appuser
# USER appuser

# 포트 노출
EXPOSE 8888

# 애플리케이션 실행
# CMD ["jupyter", "lab", "--no-browser", "--allow-root", "--ip=0.0.0.0", "--NotebookApp.token=''", "--NotebookApp.password=''"]
CMD ["sleep", "infinity"]