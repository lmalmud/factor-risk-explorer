# Use R base image with a specific version
FROM rocker/r-ver:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    pandoc \
    zlib1g-dev \
    && apt-get clean

# Install required R packages
RUN R -e "install.packages(c( \
  'DBI', 'RPostgreSQL', 'glue', 'dplyr', 'tidyverse', \
  'zoo', 'broom', 'lubridate', 'PerformanceAnalytics', \
  'knitr', 'rmarkdown', 'ggplot2', 'here' \
), repos='https://cloud.r-project.org')"

# Copy R scripts and notebooks into the image
WORKDIR /app
COPY R/ R/
COPY notebooks/ notebooks/
COPY output/ output/

# Copy database credentials (if any) and loader scripts
COPY db/ db/
COPY data_loader/ data_loader/

# Set default command (can be overridden)
CMD ["Rscript", "R/data_access.R"]

