FROM bitnami/wordpress:latest
RUN echo "GitOps Live v1.0.0" > /opt/bitnami/wordpress/build-info.txt
