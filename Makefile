SHELL := /bin/bash

install_kong_stander_routine_docker:
	docker network create kong-net || true

	docker run -d --name kong-database \
 --network=kong-net \
 -p 5432:5432 \
 -e "POSTGRES_USER=kong" \
 -e "POSTGRES_DB=kong" \
 -e "POSTGRES_PASSWORD=kongpass" \
 postgres:13

	docker run --rm --network=kong-net \
 -e "KONG_DATABASE=postgres" \
 -e "KONG_PG_HOST=kong-database" \
 -e "KONG_PG_PASSWORD=kongpass" \
 -e "KONG_PASSWORD=test" \
 kong/kong-gateway:latest kong migrations bootstrap

	docker run -d --name kong-gateway \
--network=kong-net \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database" \
-e "KONG_PG_USER=kong" \
-e "KONG_PG_PASSWORD=kongpass" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
-e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
-e KONG_LICENSE_DATA \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8444:8444 \
-p 8002:8002 \
-p 8445:8445 \
-p 8003:8003 \
-p 8004:8004 \
kong/kong-gateway:latest

	sleep 4

	curl -i -X GET --url http://localhost:8001/services

remove_kong_stander_routine:
	docker kill kong-gateway || true
	docker kill kong-database || true
	docker container rm kong-gateway || true
	docker container rm kong-database || true
	docker network rm kong-net || true

start_kong_with_custom_plugins:
	# remove old
	clear
	curl -s https://get.konghq.com/quickstart | bash -s -- -d -a kong-quickstart

	# build new image
	docker build -t kong-gateway_my-plugin:3.8-0.0.1 .
	
	# start kong with custom plugin  
	chmod +x quickstart && ./quickstart -r "" -i kong-gateway_my-plugin -t 3.8-0.0.1
	# curl -Ls https://get.konghq.com/quickstart | bash -s -- -r "" -i kong-gateway_my-plugin -t 3.8-0.0.1

	sleep 4
	
	# create service  
	curl -i -s -X POST http://localhost:8001/services --data 'name=service1' --data 'url=http://host.docker.internal:5500'
	curl -i -s -X POST http://localhost:8001/services --data 'name=service2' --data 'url=http://host.docker.internal:5500'
	
	# create route for service   
	curl -i -X POST http://localhost:8001/services/service1/routes --data 'paths[]=/mock1' --data 'name=route1'
	curl -i -X POST http://localhost:8001/services/service2/routes --data 'paths[]=/mock2' --data 'name=route2'
	
	# Create a new consumer
	curl -i -X POST http://localhost:8001/consumers/ --data 'username=consumer1'

	# Assign the consumer a key 
	curl -i -X POST http://localhost:8001/consumers/consumer1/key-auth --data 'key=eyJzdm4iOiIxIiwicmVwb3J0X2RhdGEiOiJkR1Z6ZEFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQT09In0'

	# add plugin to route
	curl -i -s -X POST http://localhost:8001/routes/route1/plugins --data 'name=attest'
	curl -i -X POST http://localhost:8001/routes/route2/plugins --data "name=tee-auth" --data "instance_name=tee-auth-route2" --data "config.key_names=apikey"

	sleep 4

	# test attest plugin
	# no config
	curl -i http://localhost:8000/mock1
	# get ng evidence
	curl -i http://localhost:8000/mock1 -H 'ng_auth:true'
	# attest service evidence
	curl -i http://localhost:8000/mock1 -H 'api:service1'
	# all func test
	curl -i http://localhost:8000/mock1 -H 'api:service1' -H 'ng_auth:true'
	
	# test tee-auth plugin
	curl -i http://localhost:8000/mock2 -H 'apikey:eyJzdm4iOiIxIiwicmVwb3J0X2RhdGEiOiJkR1Z6ZEFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQT09In0' -H 'tee:sample'
