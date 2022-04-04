[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-f059dc9a6f8d3a56e377f745f24479a46679e63a5d9fe6f495e02850cd0d8118.svg)](https://classroom.github.com/online_ide?assignment_repo_id=7080255&assignment_repo_type=AssignmentRepo)

# Shiny Spoons SFU CMPT 756 Project Repo

1. Instantiate the template files
   Fill in the required values in the template variable file
   Copy the file cluster/tpl-vars-blank.txt to cluster/tpl-vars.txt and fill in all the required values in tpl-vars.txt. These include things like your AWS keys, your GitHub signon, and other identifying information. See the comments in that file for details. Note that you will need to have installed Gatling (https://gatling.io/open-source/start-testing/) first, because you will be entering its path in tpl-vars.txt.

2. Use this step only if ZZ-REG-ID is not pointed to `scp756-221`. Update ZZ-REG-ID to `scp756-221` first in tpl-vars.txt  DO NOT commit this file
```
make -f k8s-tpl.mak templates
```

3. Open docker shell by running the below command. Make sure docker is running before executing the below command

```
tools/shell.sh
```

4. Start up an Amazon EKS cluster as follows in the shell:

```
/home/k8s# make -f eks.mak start
```

5. The ls command will determine what services are running on your cluster (the nodes).

```
/home/k8s# make -f eks.mak ls
```

6. set namespace

```
/home/k8s#  kubectl config use-context aws756
/home/k8s#  kubectl create ns c756ns
/home/k8s#  kubectl config set-context aws756 --namespace=c756ns
```

7. Installing the service mesh istio

```
/home/k8s# kubectl config use-context aws756
/home/k8s# istioctl install -y --set profile=demo --set hub=gcr.io/istio-release
/home/k8s# kubectl label namespace c756ns istio-injection=enabled
```

8. Deploying Application on cloud

```
/home/k8s# make -f k8s.mak cri
/home/k8s# make -f k8s.mak gw db s2 s3
```

8. In a separate terminal run k9s for viewing logs. Make sure to run inside shell

```
/home/k8s# k9s
```

9. Run the loader service on previous terminal

```
/home/k8s# make -f k8s.mak loader
```

10. Get external ip address

```
/home/k8s# kubectl -n istio-system get service istio-ingressgateway | cut -c -140
```

11. Use this external ip in MCLI client side application to invoke commands

```
/home/k8s# cd mcli
## if mcli is not built before. execute the build command first
/home/k8s/mcli# make build-mcli

## run mcli
/home/k8s/mcli# make PORT=80 SERVER=EXTERNAL-IP run-mcli
```

12. execude below command to test in mcli

```
read 6ecfafd0-8a35-4af6-a9e2-cbd79b3abeea
```

Fixing and redeploying a service. use rollout-{service_name}. e.g below

```
/home/k8s# make -f k8s.mak rollout-s3
```
