#!/bin/bash

NETWORK_NAME="kong-network"
COMPOSE_CMD="docker compose"

start_environment() {
  echo "🚀 Iniciando o ambiente Kong API Gateway..."

  echo "🔎 Verificando a rede Docker '$NETWORK_NAME'..."
  docker network inspect $NETWORK_NAME >/dev/null 2>&1 || {
    echo "-> Rede '$NETWORK_NAME' não encontrada. Criando..."
    docker network create $NETWORK_NAME
  }

  echo "🔄 Subindo Postgres..."
  $COMPOSE_CMD up -d kongdb
  echo "⏳ Aguardando Postgres inicializar..."
  sleep 5

  echo "⚙️ Executando migrations do Kong..."
  $COMPOSE_CMD run --rm kong-migrations
  $COMPOSE_CMD run --rm kong-migrations-up

  echo "⚙️ Preparando banco do Konga..."
  $COMPOSE_CMD run --rm konga-prepare

  echo "🔄 Subindo Kong e Konga..."
  $COMPOSE_CMD up -d kong konga

  echo ""
  echo "✅ Ambiente iniciado com sucesso!"
  echo "Kong Admin:   http://localhost:8001"
  echo "Kong Proxy:   http://localhost:9080"
  echo "Konga UI:     http://localhost:1337"
  echo ""
  echo "Use '$COMPOSE_CMD logs -f' para ver os logs dos serviços."
  echo "Use '$COMPOSE_CMD down' para parar e remover os serviços."
}

clean_environment() {
  echo "🧹 Limpando ambiente Kong API Gateway..."

  echo "Parando e removendo containers..."
  $COMPOSE_CMD down -v --remove-orphans

  echo "Removendo rede '$NETWORK_NAME'..."
  docker network rm $NETWORK_NAME >/dev/null 2>&1 || echo "-> Rede não encontrada."

  echo "✅ Ambiente limpo com sucesso!"
}

show_menu() {
  echo "====================================="
  echo "      HOSTAQUI Kong API Gateway      "
  echo "====================================="
  echo "1) Iniciar ambiente"
  echo "2) Limpar ambiente"
  echo "3) Reiniciar ambiente (limpar + iniciar)"
  echo "0) Sair"
  echo "====================================="
}

# Mostra menu apenas uma vez
show_menu
read -p "Escolha uma opção: " option

case $option in
  1) start_environment ;;
  2) clean_environment ;;
  3) clean_environment && start_environment ;;
  0) echo "Saindo..."; exit 0 ;;
  *) echo "Opção inválida, tente novamente." ;;
esac

exit 0
