help: # This help dialog
	@grep -E '^[a-zA-Z0-9 -]+:.*#'	Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

install: # initial install
	docker compose build

tests: # Run all tests
	docker compose run --rm app rake test
