#!/bin/bash

echo "================================================= Init Training Script"

echo "================================================= Init Training Script - Install Tools"
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
DEBIAN_FRONTEND=noninteractive apt-get install jq --yes

echo "================================================= Init Training Script - Install Helm"
curl https://baltocdn.com/helm/signing.asc | apt-key add -
DEBIAN_FRONTEND=noninteractive apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt update
DEBIAN_FRONTEND=noninteractive apt-get install helm --yes

echo "================================================= Init Training Script - Install ETCD Client"
DEBIAN_FRONTEND=noninteractive apt-get install etcd-client --yes

echo "================================================= Init Training Script - Install KubeSec"
wget https://github.com/controlplaneio/kubesec/releases/download/v2.11.4/kubesec_linux_amd64.tar.gz
tar -xvf kubesec_linux_amd64.tar.gz
mv kubesec /usr/local/bin/

echo "================================================= Init Training Script - Install Trivy"
DEBIAN_FRONTEND=noninteractive apt-get install wget apt-transport-https gnupg lsb-release --yes
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install trivy --yes

echo "================================================= Init Training Script - Install Kyverno"
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install --namespace kyverno --create-namespace kyverno kyverno/kyverno --version v2.3.3

echo "================================================= Init Training Script - Install AppArmor Utils"
DEBIAN_FRONTEND=noninteractive apt-get install apparmor-utils --yes

echo "================================================= Init Training Script - Install GVisor"
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://gvisor.dev/archive.key | gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" | tee /etc/apt/sources.list.d/gvisor.list > /dev/null
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y runsc
sed -i '/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes\.runc\]/i \
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]\n          runtime_type = "io.containerd.runsc.v1"\n' /etc/containerd/config.toml
systemctl restart containerd

echo "================================================= Init Training Script - Install Falco"
curl -s https://falco.org/repo/falcosecurity-packages.asc | apt-key add -
echo "deb https://download.falco.org/packages/deb stable main" | tee -a /etc/apt/sources.list.d/falcosecurity.list
apt-get update -y 
DEBIAN_FRONTEND=noninteractive apt-get --yes install linux-headers-$(uname -r)
# TODO Falco changed the installation routine completely with version 0.34.x and version 0.34.1 does not work
DEBIAN_FRONTEND=noninteractive apt-get --yes install falco=0.33.1
systemctl enable falco
systemctl start falco

echo "================================================= Init Training Script - Apply Kubernetes Manifests"
kubectl apply -f /root/pod.yaml
kubectl create clusterrolebinding my-suboptimal-clusterrolebinding --clusterrole=cluster-admin --serviceaccount default:default

echo "================================================= Init Training Script - Add Exports To .bashrc"
echo "export IP=$(hostname -i)" >> /root/.bashrc
echo "export API_SERVER=https://$(hostname -i):6443" >> /root/.bashrc
echo "export ETCDCTL_API=3" >> /root/.bashrc
echo "export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379" >> /root/.bashrc
echo "export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt" >> /root/.bashrc
echo "export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key" >> /root/.bashrc
echo "export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt" >> /root/.bashrc
echo 'PS1="\[\033[0;32m\]\u@\H \[\033[0;34m\]\w >\e[0m "' >> /root/.bashrc

echo "================================================= Init Training Script - Patching Kubelet"
mkdir -p /root/tmp
sed  's/    enabled: false/    enabled: true/g' /var/lib/kubelet/config.yaml > /root/tmp/kubelet-1.yaml
sed  's/  mode: Webhook/  mode: AlwaysAllow/g' /root/tmp/kubelet-1.yaml > /root/tmp/kubelet-2.yaml
mv /root/tmp/kubelet-2.yaml /var/lib/kubelet/config.yaml
systemctl daemon-reload
systemctl restart kubelet

echo "================================================= Init Training Script - Patching API-Server"
mkdir -p /root/apiserver
mkdir -p /root/tmp
sed  '/  volumes:/a \
  - name: lod-apiserver\
    hostPath:\
      path: /root/apiserver\
      type: DirectoryOrCreate' /etc/kubernetes/manifests/kube-apiserver.yaml > /root/tmp/apiserver-1.yaml
sed  '/  volumeMounts:/a \
    - name: lod-apiserver\
      mountPath: /apiserver' /root/tmp/apiserver-1.yaml > /root/tmp/apiserver-2.yaml
mv /root/tmp/apiserver-2.yaml /etc/kubernetes/manifests/kube-apiserver.yaml

echo "================================================= Init Training Script - Finished successfully"

