#!/bin/bash
#
# functions for setting up app backend
#######################################
# creates REDIS db using docker
# Arguments:
#   None
#######################################
backend_redis_create() {
  print_banner
  printf "${WHITE} 💻 Criando Redis & Banco Postgres...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Redis, Docker e Postgres suportam esta versão."
  fi
  usermod -aG docker deploy
  docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always --detach redis redis-server --requirepass ${mysql_root_password}
  sleep 2
  sudo su - postgres
  createdb ${instancia_add};
  psql
  CREATE USER ${instancia_add} SUPERUSER INHERIT CREATEDB CREATEROLE;
  ALTER USER ${instancia_add} PASSWORD '${mysql_root_password}';
  \q
  exit
EOF

sleep 2

}

#######################################
# sets environment variable for backend.
# Arguments:
#   None
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  # ensure idempotency
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/backend/.env
NODE_ENV=
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=${backend_port}

DB_HOST=localhost
DB_DIALECT=postgres
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}
DB_PORT=5432

GEMINI_API_KEY=AIzaSyBSfas1EubBL1MvtwIqmF6_gJko6s_BjyY

CERTIFICADOS=false
HTTPS=false
SSL_CRT_FILE=F:\\bkpidx\\workflow\\backend\\certs\\localhost.pem
SSL_KEY_FILE=F:\\bkpidx\\workflow\\backend\\certs\\localhost-key.pem

TIMEOUT_TO_IMPORT_MESSAGE=999
FLUSH_REDIS_ON_START=true
DEBUG_TRACE=false

APP_TRIALEXPIRATION=7



REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000
REDIS_HOST=127.0.0.1
REDIS_PORT=${redis_port}
REDIS_PASSWORD=${mysql_root_password}

JWT_SECRET=Di0LisB99vHv/c6z+hRGd53MkxGYR/XhABe0SsrzJu0=
JWT_REFRESH_SECRET=0DOH9hUi0SiKPD67l1WTfE0M4uRx3nkDmvyIHN1Sfhs=

COMPANY_TOKEN=whaticket
PERFEX_URL=
PERFEX_MODULE=

VERIFY_TOKEN=whaticket

#METODOS DE PAGAMENTO
STRIPE_PRIVATE=
STRIPE_OK_URL=BACKEND_URL/subscription/stripewebhook
STRIPE_CANCEL_URL=FRONTEND_URL/financeiro

MP_ACCESS_TOKEN=
MP_NOTIFICATION_URL=BACKEND_URL/subscription/mercadopagowebhook

ASAAS_TOKEN=

GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=
GERENCIANET_CLIENT_SECRET=
GERENCIANET_PIX_CERT=
GERENCIANET_PIX_KEY=

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}
CLOSED_SEND_BY_ME=true

MASTER_KEY=senha_master
TIMEOUT_TO_IMPORT_MESSAGE=1000

FACEBOOK_APP_ID=
FACEBOOK_APP_SECRET=

MAIL_HOST="smtp.gmail.com"
MAIL_USER="seu@gmail.com"
MAIL_PASS="SuaSenha"
MAIL_FROM="seu@gmail.com"
MAIL_PORT="465"

[-]EOF
EOF

  sleep 2
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${instancia_add}/backend
  npm install
EOF

  sleep 2
}

#######################################
# compiles backend code
# Arguments:
#   None
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${instancia_add}/backend
  npm run build
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${empresa_atualizar}
  pm2 stop ${empresa_atualizar}-backend
  git pull
  cd /home/deploy/${empresa_atualizar}/backend
  npm install --f
  npm update
  rm -rf dist 
  npm run build
  npx sequelize db:migrate
  npx sequelize db:seed:all
  pm2 start ${empresa_atualizar}-backend
  pm2 save 
EOF

  sleep 2
}

#######################################
# runs db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${instancia_add}/backend
  npx sequelize db:migrate
EOF

  sleep 2
}

#######################################
# runs db seed
# Arguments:
#   None
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Executando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${instancia_add}/backend
  npx sequelize db:seed:all
EOF

  sleep 2
}

#######################################
# starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${instancia_add}/backend
  pm2 start dist/server.js --name ${instancia_add}-backend
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Nginx suporta esta versão."
  fi
  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${instancia_add}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}
