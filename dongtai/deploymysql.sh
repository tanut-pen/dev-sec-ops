kubectl apply -n dongtai -f - <<EOF            󱃾 rancher-lab  14:56:47
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: dongtai
spec:
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql
  replicas: 1
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: dongtai/dongtai-mysql:latest   # ← pre-loaded with schema
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "dongtai-iast"
        ports:
        - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: dongtai
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
EOF                                                                        