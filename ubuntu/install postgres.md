```bash
sudo apt install -y curl ca-certificates gnupg lsb-release
```


curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
| sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg

echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
http://apt.postgresql.org/pub/repos/apt \
$(lsb_release -cs)-pgdg main" \
| sudo tee /etc/apt/sources.list.d/pgdg.list


sudo apt update

sudo apt install -y postgresql-17 postgresql-client-17

sudo systemctl status postgresql

psql --version


sudo -i -u postgres

psql

## later


sudo -u postgres psql

sudo nano /etc/postgresql/17/main/postgresql.conf
listen_addresses = '*'

sudo nano /etc/postgresql/17/main/pg_hba.conf
host    all     all     0.0.0.0/0     scram-sha-256

sudo systemctl restart postgresql
sudo ufw allow 5432


# set password

sudo -u postgres psql

CREATE DATABASE appdb;
CREATE USER appuser WITH ENCRYPTED PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
\q
