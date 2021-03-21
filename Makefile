.PHONY: help install start new-post

help: ## Display available commands
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

start: ## start dev server
	zola serve

build: ## Build files for production
	zola build

deploy: build ## Deploy static site
	rsync -avz --delete public/ caencamp:/home/websites/alexis/alexisjanvier_net/www/
