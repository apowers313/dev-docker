.PHONY: build run shell login publish
DOCKER=sudo docker
#BUILD_EXTRA=--progress=plain
IMGNAME=apowers313/dev
VERSION=1.0.0
GITPKG=ghcr.io/$(IMGNAME)
# RUNCMD=run -p 6379:6379 -it --privileged $(IMGNAME):latest
SUPERVISOR_PORT=8001:8001
INDEX_PORT=80:80
JUPYTER_PORT=8002:8002
VSCODE_PORT=8004:8004
RUNCMD=run -p $(SUPERVISOR_PORT) -p $(INDEX_PORT) -p $(VSCODE_PORT) -p $(JUPYTER_PORT) -it $(IMGNAME):latest

build:
	$(DOCKER) build . --build-arg DEV_PASSWORD=$(DEV_PASSWORD) $(BUILD_EXTRA) -t $(IMGNAME):latest

run:
	$(DOCKER) $(RUNCMD)

shell:
	$(DOCKER) $(RUNCMD) bash

# login requires a Personal Access Token (PAT): https://github.com/settings/tokens
login:
	$(DOCKER) login ghcr.io

publish:
	$(DOCKER) tag $(IMGNAME):latest $(GITPKG):latest
	$(DOCKER) tag $(IMGNAME):latest $(GITPKG):$(VERSION)
	$(DOCKER) push $(GITPKG):latest
	$(DOCKER) push $(GITPKG):$(VERSION)
