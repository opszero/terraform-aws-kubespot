.PHONY=build
push:
	docker build -t opszero/deploytag:go-rewrite .
	docker push opszero/deploytag:go-rewrite

