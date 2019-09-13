.PHONY=build
push:
	docker build -t opszero/deploytag:go-rewrite2 .
	docker push opszero/deploytag:go-rewrite2

