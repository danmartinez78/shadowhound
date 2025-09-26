# Makefile convenience targets
SHELL := /bin/bash

.PHONY: preflight docker-preflight-laptop docker-preflight-thor logs clean

preflight:
	./scripts/ci_preflight.sh

docker-preflight-laptop:
	docker compose --profile laptop build
	docker compose --profile laptop run --rm shadowhound bash -lc 'source /ws/install/setup.bash && ros2 pkg list | grep shadowhound_mission_agent && echo OK'

docker-preflight-thor:
	docker compose --profile thor build
	docker compose --profile thor run --rm shadowhound-thor bash -lc 'source /ws/install/setup.bash && ros2 pkg list | grep shadowhound_mission_agent && echo OK'

logs:
	docker compose logs -f

clean:
	rm -rf build/ install/ log/
