

sudo rm -rf /usr/local/go

curl -LO https://go.dev/dl/go1.24.5.linux-amd64.tar.gz


sudo tar -C /usr/local -xzf go1.24.5.linux-amd64.tar.gz

nano ~/.profile

export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go


source ~/.profile

go version