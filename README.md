# Workspace

python3.11  
cpu version  
Dockerfile & jupyter lab config  

```
docker build -t workspace:latest .
```

```
docker run -td \
  --name Workspace \
  -p 8888:8888 -p 5000-5002:5000-5002 \
  -v $(pwd):/app \
  workspace:latest
```
