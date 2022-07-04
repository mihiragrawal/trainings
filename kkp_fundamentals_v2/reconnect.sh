export GOOGLE_CREDENTIALS=$(cat ~/secrets/key.json)

eval `ssh-agent`
ssh-add ~/secrets/kkp_admin_training

sudo apt-get install -y uuid-runtime apache2-utils 

chmod +x ~/.tmp/kubeone/kubeone
sudo cp ~/.tmp/kubeone/kubeone /usr/local/bin

chmod +x ~/.tmp/kkp/kubermatic-installer
sudo cp ~/.tmp/kkp/kubermatic-installer /usr/local/bin

chmod +x ~/.tmp/kkp-2.20.4/kubermatic-installer
sudo cp ~/.tmp/kkp-2.20.4/kubermatic-installer /usr/local/bin

export KUBECONFIG=~/kubeone/kkp-admin-kubeconfig

source <(kubectl completion bash)