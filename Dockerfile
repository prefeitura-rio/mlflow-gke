ARG PYTHON_VERSION=3.10
FROM python:${PYTHON_VERSION}

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential gcc python3-dev python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install miniconda
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
RUN curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm Miniconda3-latest-Linux-x86_64.sh

# Setup virtual environment
ENV VENV=/.venv/myenv
ENV PATH=$VENV/bin:$PATH
ARG MLFLOW_VERSION=2.10.2
RUN python3 -m venv ${VENV} && \
    mkdir -p $VENV/src && \
    python -m pip install --no-cache-dir --prefer-binary -U pip && \
    python -m pip install --no-cache-dir --prefer-binary psycopg2 mlflow==${MLFLOW_VERSION} google-cloud google-cloud-storage scikit-learn xgboost

# Mount the credentials json file under the following directory
WORKDIR /workdir/
RUN mkdir -p /workdir/gcloud-credentials/ && \
    curl https://sdk.cloud.google.com > install.sh && \
    bash install.sh --disable-prompts --install-dir=/workdir/
ENV PATH=/workdir/google-cloud-sdk/bin:$PATH

# Expose the port that the MLFlow tracking server runs on
EXPOSE 5000

# The command defaults to running the MLFlow tracking server
CMD ["bash", "-c", "gcloud auth activate-service-account --key-file=/workdir/gcloud-credentials/gcloud-credentials.json && mlflow server --default-artifact-root $ARTIFACT_STORE --backend-store-uri postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_URL/$DB_NAME --host 0.0.0.0"]