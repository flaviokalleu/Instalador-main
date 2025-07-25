#!/bin/bash
# 
# functions for setting up app frontend

#######################################
# installed node packages
# Arguments:
#   None
#######################################
frontend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${instancia_add}/frontend
  npm i --f
EOF

  sleep 2
}

#######################################
# compiles frontend code
# Arguments:
#   None
#######################################
frontend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${instancia_add}/frontend
  npm run build
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
frontend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Node.js, dependências e PM2 suportam esta versão."
  fi
  cd /home/deploy/${empresa_atualizar}
  git fetch
  git pull
  cd /home/deploy/${empresa_atualizar}/frontend
  npm i --f
  rm -rf build
  npm run build
EOF

  sleep 2
}


#######################################
# sets frontend environment variables
# Arguments:
#   None
#######################################
frontend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - deploy << EOF1
  cat <<-EOF2 > /home/deploy/${instancia_add}/frontend/.env
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_BACKEND_PROTOCOL=https
REACT_APP_BACKEND_HOST=${backend_hostname}
REACT_APP_BACKEND_PORT=443
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
REACT_APP_LOCALE=pt-br
REACT_APP_TIMEZONE=America/Sao_Paulo
REACT_APP_NUMBER_SUPPORT=556196080740

CERTIFICADOS=false
HTTPS=false
SSL_CRT_FILE=F:\\bkpidx\\workflow\\backend\\certs\\localhost.pem
SSL_KEY_FILE=F:\\bkpidx\\workflow\\backend\\certs\\localhost-key.pem

REACT_APP_FACEBOOK_APP_ID=2813216208828642
FACEBOOK_APP_ID=2813216208828642
FACEBOOK_APP_SECRET=8233912aeade366dd8e2ebef6be256b6

EOF2
EOF1

  sleep 2

}

#######################################
# sets up nginx for frontend
# Arguments:
#   None
#######################################
frontend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Detecta codinome do Ubuntu
  UBUNTU_CODENAME=$(lsb_release -cs)
  if [ "$UBUNTU_CODENAME" = "oracular" ]; then
    echo "[INFO] Ubuntu 25 detectado (codinome: oracular). Verifique se o Nginx suporta esta versão."
  fi
  frontend_hostname=$(echo "${frontend_url/https:\/\/}")

sudo su - root << EOF

cat > /etc/nginx/sites-available/${instancia_add}-frontend << 'END'

server {
  server_name $frontend_hostname;
  
  root /home/deploy/${instancia_add}/frontend/build;
  index index.html index.htm index.nginx-debian.html;

location / {
      try_files \$uri /index.html;
  }
}
END

ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled
EOF

  sleep 2
}
