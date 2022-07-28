FROM python:3.9-slim AS base

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

FROM base AS python-deps

# Install depedencies
RUN apt-get update && apt-get install -y --no-install-recommends gcc

COPY pyproject.toml .
RUN poetry install


# Install application into container
COPY . .

# Run the executable
ENTRYPOINT [ "python3", "-m", src.train ]