apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app_name}-deployment
  labels:
    app: ${app_name}
spec:
  replicas: ${app_replicas}
  selector:
    matchLabels:
      app: ${app_name}
  template:
    metadata:
      labels:
        app: ${app_name}
    spec:
      containers:
      - name: ${app_name}
        image: ${dockerhub_image_tag}
        ports:
        - containerPort: ${app_port}
---
apiVersion: v1
kind: Service
metadata:
  name: ${app_name}-nodeport
spec:
  type: NodePort
  selector:
    app: ${app_name}
  ports:
  - name: http
    port: ${app_port}
    targetPort: ${app_port}
    nodePort: ${app_nodeport}

