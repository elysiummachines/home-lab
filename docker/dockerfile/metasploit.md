```sh
FROM debian:12-slim

# Set environment variables
ENV USER msf_user
ENV HOME /home/${USER}
ENV SHELL /bin/bash
ENV TZ America/Calgary

# Update system & install necessary packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
        build-essential \
        zlib1g zlib1g-dev \
        libxml2 libxml2-dev \
        libxslt-dev \
        libreadline-dev \
        libcurl4-openssl-dev \
        git-core \
        libssl-dev \
        libyaml-dev \
        autoconf \
        libtool \
        ncurses-dev \
        bison \
        wget \
        vim \
        curl \
        net-tools \
        iputils-ping \
        nmap \
        python3-pip \
        postgresql \
        postgresql-contrib \
        sudo \
        tzdata && \
    apt-get clean

# Ensure necessary directories exist & have correct ownership
RUN mkdir -p /etc/sudoers.d /var/run/postgresql /var/lib/postgresql/15/main /opt/logs && \
    chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql /opt/logs

# Add non-root user
RUN useradd -m ${USER} && \
    gpasswd -a ${USER} sudo && \
    echo "${USER}:msf_pass" | chpasswd && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 440 /etc/sudoers.d/${USER}

# Initialize PostgreSQL database
USER postgres
RUN rm -rf /var/lib/postgresql/15/main/* && \
    /usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/15/main && \
    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/main -l /opt/logs/postgres.log start && \
    psql --command "CREATE USER msf_user WITH SUPERUSER PASSWORD 'msf_pass';" && \
    createdb --owner=msf_user msf_database && \
    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/main stop

# Configure PostgreSQL to allow remote connections
USER root
RUN echo "host all  all    0.0.0.0/0  md5" >> /var/lib/postgresql/15/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /var/lib/postgresql/15/main/postgresql.conf

# Install Metasploit Framework
RUN curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -o /tmp/msfinstall && \
    chmod +x /tmp/msfinstall && \
    /tmp/msfinstall && \
    rm -rf /tmp/msfinstall && \
    chown -R ${USER}:${USER} /opt/metasploit-framework

# Expose necessary ports
EXPOSE 5432

# Set working directory
WORKDIR /opt/metasploit-framework/

# Default command
CMD ["bash"]
```
