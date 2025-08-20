#!/bin/bash

# Script de Diagnóstico para Erro 502 Nginx
# Execute com: bash diagnostico_502.sh

echo "🔍 Iniciando diagnóstico do erro 502..."
echo "========================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para imprimir status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo -e "\n${YELLOW}1. Verificando PM2...${NC}"
if command_exists pm2; then
    echo "PM2 encontrado, verificando status..."
    pm2 status > /dev/null 2>&1
    print_status $? "PM2 está rodando"
    
    echo "Verificando processo beta-back..."
    pm2 list | grep -q "beta-back"
    print_status $? "Processo beta-back existe"
else
    echo -e "${RED}❌ PM2 não encontrado${NC}"
fi

echo -e "\n${YELLOW}2. Verificando Nginx...${NC}"
if command_exists nginx; then
    echo "Testando configuração do nginx..."
    sudo nginx -t > /dev/null 2>&1
    print_status $? "Configuração nginx válida"
    
    echo "Verificando status do nginx..."
    sudo systemctl is-active nginx > /dev/null 2>&1
    print_status $? "Nginx está ativo"
else
    echo -e "${RED}❌ Nginx não encontrado${NC}"
fi

echo -e "\n${YELLOW}3. Verificando portas...${NC}"
# Verificar porta 8080 (backend)
if netstat -tlnp 2>/dev/null | grep -q ":8080"; then
    echo -e "${GREEN}✅ Porta 8080 está em uso${NC}"
else
    echo -e "${RED}❌ Porta 8080 não está em uso${NC}"
fi

# Verificar porta 80 (nginx)
if netstat -tlnp 2>/dev/null | grep -q ":80"; then
    echo -e "${GREEN}✅ Porta 80 está em uso${NC}"
else
    echo -e "${RED}❌ Porta 80 não está em uso${NC}"
fi

# Verificar porta 443 (nginx SSL)
if netstat -tlnp 2>/dev/null | grep -q ":443"; then
    echo -e "${GREEN}✅ Porta 443 está em uso${NC}"
else
    echo -e "${RED}❌ Porta 443 não está em uso${NC}"
fi

echo -e "\n${YELLOW}4. Testando conectividade local...${NC}"
# Testar se a aplicação responde localmente
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|404"; then
    echo -e "${GREEN}✅ Aplicação responde na porta 8080${NC}"
else
    echo -e "${RED}❌ Aplicação não responde na porta 8080${NC}"
fi

echo -e "\n${YELLOW}5. Verificando recursos do sistema...${NC}"
# Verificar uso de memória
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
echo "Uso de memória: ${MEMORY_USAGE}%"
if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    echo -e "${RED}⚠️  Uso de memória alto${NC}"
else
    echo -e "${GREEN}✅ Uso de memória OK${NC}"
fi

# Verificar espaço em disco
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "Uso de disco: ${DISK_USAGE}%"
if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "${RED}⚠️  Espaço em disco baixo${NC}"
else
    echo -e "${GREEN}✅ Espaço em disco OK${NC}"
fi

echo -e "\n${YELLOW}6. Verificando logs recentes...${NC}"
echo "Últimas 5 linhas do log de erro do nginx:"
if [ -f "/var/log/nginx/error.log" ]; then
    sudo tail -5 /var/log/nginx/error.log
else
    echo -e "${RED}❌ Log de erro do nginx não encontrado${NC}"
fi

echo -e "\n${YELLOW}7. Verificando certificados SSL...${NC}"
if [ -d "/etc/letsencrypt/live" ]; then
    echo "Certificados Let's Encrypt encontrados:"
    ls /etc/letsencrypt/live/
    
    # Verificar validade dos certificados
    for domain in /etc/letsencrypt/live/*; do
        if [ -d "$domain" ]; then
            domain_name=$(basename "$domain")
            if [ "$domain_name" != "README" ]; then
                echo "Verificando certificado para: $domain_name"
                if sudo openssl x509 -checkend 86400 -noout -in "$domain/fullchain.pem" > /dev/null 2>&1; then
                    echo -e "${GREEN}✅ Certificado válido${NC}"
                else
                    echo -e "${RED}❌ Certificado expirado ou próximo do vencimento${NC}"
                fi
            fi
        fi
    done
else
    echo -e "${RED}❌ Certificados Let's Encrypt não encontrados${NC}"
fi

echo -e "\n${YELLOW}8. Verificando firewall...${NC}"
if command_exists ufw; then
    echo "Status do UFW:"
    sudo ufw status
else
    echo "UFW não encontrado"
fi

echo -e "\n${YELLOW}9. Verificando arquivos de build...${NC}"
if [ -f "backend/dist/server.js" ]; then
    echo -e "${GREEN}✅ Backend build encontrado${NC}"
else
    echo -e "${RED}❌ Backend build não encontrado${NC}"
fi

if [ -d "frontend/build" ]; then
    echo -e "${GREEN}✅ Frontend build encontrado${NC}"
else
    echo -e "${RED}❌ Frontend build não encontrado${NC}"
fi

echo -e "\n${YELLOW}10. Sugestões de correção...${NC}"
echo "Se encontrou problemas, execute os seguintes comandos:"

echo -e "\n${GREEN}Para reiniciar serviços:${NC}"
echo "sudo systemctl restart nginx"
echo "pm2 restart all"

echo -e "\n${GREEN}Para ver logs em tempo real:${NC}"
echo "pm2 logs beta-back --lines 50 -f"
echo "sudo tail -f /var/log/nginx/error.log"

echo -e "\n${GREEN}Para verificar configuração nginx:${NC}"
echo "sudo nginx -t"
echo "sudo cat /etc/nginx/sites-available/seu-dominio"

echo -e "\n${GREEN}Para testar conectividade:${NC}"
echo "curl -v http://localhost:8080"
echo "curl -v https://seu-dominio.com/api/"

echo -e "\n${YELLOW}========================================"
echo "Diagnóstico concluído!${NC}"
