# Workspace
Workspace.docker

```
docker build -t workspace-img:250613 .


docker run -td --init --name workspace \
-v ~/Workspace:/app \
-p 8888:8888 \
workspace-img:250613


docker exec -it workspace bash
```

- PID 1: `CMD ["sleep", "infinity"]`
- dev-container vscode에 extensions 설치
- (선택) automl 사전설정(requirements, kubeflow-config)

