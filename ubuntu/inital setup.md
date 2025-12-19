

```bash
sudo apt update && sudo apt upgrade -y
```

```bash
adduser username
```


```bash
usermod -aG sudo username
```
```bash
su - username
sudo whoami
```

for deleting user
```bash
sudo userdel adarsh
```

### In local computer
```bash
ssh-keygen -t ed25519
ssh-copy-id username@SERVER_IP
```


## in remote server
```bash
sudo nano /etc/ssh/sshd_config
```

```bash
sudo systemctl restart ssh
```

```bash
sudo timedatectl set-timezone Asia/Kolkata   
timedatectl
```
```bash
sudo apt install fail2ban -y
```
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```
```bash
sudo fail2ban-client status
```
```bash
sudo apt install -y curl wget git htop unzip net-tools
```

