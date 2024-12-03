FROM kong/kong-gateway:3.8.0.0
# Ensure any patching steps are executed as root user
USER root

RUN apt-get update
RUN apt-get install -y curl iputils-ping python3

# Add custom plugin to the image
COPY ./kong/plugins/api-version /usr/local/share/lua/5.1/kong/plugins/api-version
COPY ./kong/plugins/attest /usr/local/share/lua/5.1/kong/plugins/attest
COPY ./kong/plugins/tee-auth /usr/local/share/lua/5.1/kong/plugins/tee-auth
ENV KONG_PLUGINS=bundled,attest,api-version,tee-auth

# Ensure kong user is selected for image execution
USER kong

# Run kong
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]
