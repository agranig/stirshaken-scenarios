image:=stirshaken-scenarios
version:=latest
container:=stirshaken-scenarios

#######################################################
# Docker params
#######################################################

RUN_PARAMS:=--name ${container} \
			--net=host

SHELL_PARAMS:=${RUN_PARAMS} \
			-v $(PWD):/opt/stirshaken-scenarios


#######################################################
# Docker targets
#######################################################

build:
	@docker build -t ${image}:${version} --network host .

run: pre-run
	@docker run ${RUN_PARAMS} ${image}:${version}

shell: pre-run
	@docker run -it --entrypoint /bin/bash ${RUN_PARAMS} ${image}:${version}


#######################################################
# Commands for interacting with a container
#######################################################

attach:
	@docker exec -it ${container} bash

logs:
	@docker logs  -f --since 1m ${container}

stop:
	@docker stop ${container}

kill:
	@docker kill ${container}

rm:
	@docker rm ${container}


#######################################################
# Internal targets
#######################################################

rm-silent:
	@docker rm ${container} 2> /dev/null || true

pre-run: rm-silent

.PHONY: build run shell
