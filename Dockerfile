# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# ==================================================================
FROM python:3.11.7 as base


ENV LANG C.UTF-8
WORKDIR /app


RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \

    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \

    apt-get update && \

# ==================================================================
# tools
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        git \
        vim \
        libssl-dev \
        curl \
        unzip \
        cmake \
        htop \
        && \

    python3 -m pip install --upgrade pip

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

## Create a non-privileged user that the app will run under.
## See https://docs.docker.com/go/dockerfile-user-best-practices/
# ARG UID=10001
# RUN adduser \
#     --disabled-password \
#     --gecos "" \
#     --home "/nonexistent" \
#     --shell "/sbin/nologin" \
#     --no-create-home \
#     --uid "${UID}" \
#     appuser

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.

# RUN --mount=type=cache,target=/root/.cache/pip \
RUN --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip --no-cache-dir install -r requirements.txt && \


# ==================================================================
# config & cleanup
# ------------------------------------------------------------------

    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*


## Switch to the non-privileged user to run the application.
# USER appuser

## Copy the source code into the container.
# COPY . .
COPY .jupyter /root/.jupyter

# Expose the port that the application listens on.
EXPOSE 8888

# Run the application.
CMD ["bash", "-c", "jupyter lab --no-browser --allow-root --ip=0.0.0.0"]

