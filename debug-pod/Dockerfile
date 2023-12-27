FROM ubuntu:23.10

WORKDIR /root
RUN apt update
RUN apt -y install curl unzip less jq python3 pip libpq-dev postgresql-client-15 vim
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
#CMD ["tail", "-f", "/dev/null"]
