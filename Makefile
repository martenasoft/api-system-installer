.PHONY: help
help:
	@echo "Доступные команды:"

PROJECTS = user-api
REPO_user-api = https://github.com/martenasoft/api-system-user.git

# Установка зависимостей
.PHONY: install
install:
	@if [ -z "$(name)" ]; then \
		echo "Set path to your project (example: make install name=my-api path=/var/www/my-project)"; \
		exit 1; \
	fi

	@if [ -z "$(path)" ]; then \
		echo "Set path to your project (example: make install name=my-api path=/var/www/my-project)"; \
		exit 1; \
	fi

	@for proj in $(PROJECTS); do \
		projPath="$(path)/$$proj"; \
		echo "Install to: $$projPath"; \
		if [ ! -d "$$projPath" ]; then \
			echo "Cloning into: $$projPath"; \
			git clone https://github.com/api-platform/api-platform "$$projPath"; \
		fi; \
		rm -rf "/tmp/martenasoft-api-system/$$proj"; \
		if [ "$$proj" = 'user-api' ]; then \
			echo "Cloning repo: https://github.com/martenasoft/api-system-user.git into /tmp/martenasoft-api-system/$$proj"; \
			git clone https://github.com/martenasoft/api-system-user.git "/tmp/martenasoft-api-system/$$proj"; \
			echo "Copying files from /tmp/martenasoft-api-system/$$proj to $$projPath/api/"; \
		fi; \
		localDomain="$$name-$$proj"; \
		cp -rf "/tmp/martenasoft-api-system/$$proj/"* "$$projPath/api/"; \
		if [ ! -f "$$projPath/api/.symfony.local.yaml" ]; then \
			echo "Adding file: $$projPath/api/.symfony.local.yaml"; \
			printf "proxy:\n\tdomains:\n\t\t- $$localDomain\n" > "$$projPath/api/.symfony.local.yaml"; \
			echo "Attach local domain: $$localDomain"; \
            symfony proxy:domain:attach "$$localDomain" --dir "$$projPath"; \
		fi; \
		if [ ! -d "$$projPath/api/config/packages/dev" ]; then \
			echo "Creating directory: $$projPath/api/config/packages/dev"; \
			mkdir -p "$$projPath/api/config/packages/dev"; \
		fi; \
		if [ ! -f "$$projPath/api/config/packages/dev/http_client_proxy.yaml" ]; then \
			echo "Adding file: $$projPath/api/config/packages/dev/http_client_proxy.yaml"; \
			printf "framework:\n\thttp_client:\n\t\tdefault_options:\n\t\t\tproxy: http://127.0.0.1:7080\n\t\t\tverify_host: false\n\t\t\tverify_peer: false\n" > "$$projPath/api/config/packages/dev/http_client_proxy.yaml"; \
		fi; \
	done

	@echo "Restarting symfony proxy"; \
	symfony proxy:stop; \
	symfony proxy:start; \

	@for proj in $(PROJECTS); do \
		projPath="$(path)/$$proj"; \
		echo "Restarting server: $$projPath"; \
		symfony server:stop --dir "$$projPath"; \
		symfony serve -d --dir "$$projPath"; \
	done

	symfony proxy:status; \
