#!/bin/bash

# Script de automatización para despliegue DevOps
# Autor: Santiago Valencia García
# Código: A00395902
# Fecha: 06/08/2025

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

IMAGE_NAME="devops-evaluation-app"
CONTAINER_NAME="devops-app-container"
PORT=8080
NODE_ENV=production

echo -e "${BLUE}=== Script de Automatización DevOps ===${NC}"
echo -e "${BLUE}Iniciando proceso de despliegue...${NC}\n"

print_error() {
    echo -e "${RED} ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN} ÉXITO: $1${NC}"
}

print_info() {
    echo -e "${YELLOW} INFO: $1${NC}"
}

echo -e "${BLUE}1. Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    echo "Por favor, instala Docker primero:"
    echo "curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "sudo sh get-docker.sh"
    exit 1
fi

if ! docker --version &> /dev/null; then
    print_error "Docker no está ejecutándose"
    echo "Inicia el servicio de Docker:"
    echo "sudo systemctl start docker"
    exit 1
fi

print_success "Docker está instalado y ejecutándose"
echo "Versión: $(docker --version)"

echo -e "\n${BLUE}2. Limpiando recursos anteriores...${NC}"
if docker ps -a | grep -q $CONTAINER_NAME; then
    print_info "Deteniendo y eliminando contenedor anterior..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

if docker images | grep -q $IMAGE_NAME; then
    print_info "Eliminando imagen anterior..."
    docker rmi $IMAGE_NAME 2>/dev/null || true
fi

echo -e "\n${BLUE}3. Construyendo imagen Docker...${NC}"
if docker build -t $IMAGE_NAME .; then
    print_success "Imagen construida exitosamente"
else
    print_error "Falló la construcción de la imagen"
    exit 1
fi

echo -e "\n${BLUE}4. Ejecutando contenedor...${NC}"
if docker run -d \
    --name $CONTAINER_NAME \
    -p $PORT:3000 \
    -e NODE_ENV=$NODE_ENV \
    -e PORT=3000 \
    $IMAGE_NAME; then
    print_success "Contenedor iniciado exitosamente"
else
    print_error "Falló al iniciar el contenedor"
    exit 1
fi

echo -e "\n${BLUE}5. Esperando que el servicio esté listo...${NC}"
sleep 5

echo -e "\n${BLUE}6. Realizando prueba de conectividad...${NC}"
if curl -s http://localhost:$PORT > /dev/null; then
    print_success "Servicio responde correctamente"
    echo -e "Respuesta del servidor:"
    curl -s http://localhost:$PORT | python3 -m json.tool 2>/dev/null || curl -s http://localhost:$PORT
else
    print_error "El servicio no responde"
    echo "Revisando logs del contenedor:"
    docker logs $CONTAINER_NAME
    exit 1
fi

echo -e "\n${BLUE}7. Probando endpoint de salud...${NC}"
if curl -s http://localhost:$PORT/health | grep -q "OK"; then
    print_success "Health check exitoso"
else
    print_error "Health check falló"
fi

echo -e "\n${GREEN}=== RESUMEN DEL DESPLIEGUE ===${NC}"
echo -e "${GREEN} Estado: EXITOSO${NC}"
echo -e "Imagen: $IMAGE_NAME"
echo -e "Contenedor: $CONTAINER_NAME"
echo -e "URL: http://localhost:$PORT"
echo -e "Health Check: http://localhost:$PORT/health"
echo -e "Entorno: $NODE_ENV"

echo -e "\n${BLUE}Comandos útiles:${NC}"
echo -e "Ver logs: ${YELLOW}docker logs $CONTAINER_NAME${NC}"
echo -e "Detener: ${YELLOW}docker stop $CONTAINER_NAME${NC}"
echo -e "Iniciar: ${YELLOW}docker start $CONTAINER_NAME${NC}"
echo -e "Eliminar: ${YELLOW}docker rm $CONTAINER_NAME${NC}"

echo -e "\n${GREEN} ¡Despliegue completado exitosamente!${NC}"