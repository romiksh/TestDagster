FROM python:3.11-slim
RUN apt-get update && apt-get install -y --no-install-recommends build-essential curl && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir dagster dagster-webserver dagster-postgres dagster-aws
ENV DAGSTER_HOME=/opt/dagster/dagster_home
RUN mkdir -p $DAGSTER_HOME
COPY user_data/dagster_home/dagster.yaml   $DAGSTER_HOME/dagster.yaml
COPY user_data/dagster_home/workspace.yaml $DAGSTER_HOME/workspace.yaml
COPY user_data/dagster_home/repository.py $DAGSTER_HOME/repository.py
WORKDIR /app
COPY app /app
CMD ["dagster-webserver","-h","0.0.0.0","-p","3000","-w","/opt/dagster/dagster_home/workspace.yaml"]
