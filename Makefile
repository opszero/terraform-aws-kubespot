.PHONY=build
push:
	docker build -t opszero/deploytag:v2 .
	docker push opszero/deploytag:v2

