FROM python:3.6-alpine

LABEL MAINTAINER="Brad Campbell <b@bradcod.es>"

WORKDIR /opt/src

COPY cloud-custodian .

RUN pip install -r requirements.txt && \
	python setup.py install && \
	cd tools/c7n_mailer/ && \
	pip install -r requirements.txt && \
	python setup.py install

WORKDIR /opt/src
COPY policy.yml policy.yml
COPY mailer.yml mailer.yml

ENTRYPOINT [ "/bin/sh" ]