default: help

help: #: Show help topics
	@grep "#:" Makefile* | grep -v "@grep" | sort | sed "s/\([A-Za-z_ -]*\):.*#\(.*\)/$$(tput setaf 3)\1$$(tput sgr0)\2/g"

build: #: Build containers
	docker-compose build

up: #: Start containers
	docker-compose up -d

stop: #: Stop running containers
	docker-compose stop

down: #: Bring down the service
	docker-compose down

ps: #: Show running processes
	docker-compose ps

rspec: #: Run Rspec in running containers (can use arg)
	docker compose exec app bundle exec rspec $(filter-out $@,$(MAKECMDGOALS))


.PHONY: app test spec lib docs bin config db tmp temp
