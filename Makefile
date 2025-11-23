MAKE=make -C

DOCKER_BUILD=docker build
DOCKER_BUILD_OPTS=--no-cache
DOCKER_RMI=docker rmi -f

ISUPIPE_TAG=isupipe:latest

test: test_benchmarker
.PHONY: test

test_benchmarker:
	$(MAKE) bench test
.PHONY: test_benchmarker

build_webapp:
	$(MAKE) webapp/go docker_image
.PHONY: build_webapp

.PHONY: bench clear-slow-log mysql-config analyze full-bench

bench:
	cd bench && make bench

clear-slow-log:
	truncate -s 0 development/slow.log 2>/dev/null || true
	docker exec mysql truncate -s 0 /var/lib/mysql/slow.log 2>/dev/null || true

mysql-config:
	docker exec mysql mysql -uroot -proot -e "SET GLOBAL long_query_time = 0.1; SET GLOBAL slow_query_log_file = '/var/lib/mysql/slow.log';" 2>&1 | grep -v Warning || true

analyze:
	sleep 5
	cd development/scripts && ./pt-query-digest.sh --order-by Query_time:sum --limit 10

full-bench: clear-slow-log bench mysql-config analyze

