# Diagnóstico do Erro 502 Nginx em Produção

## 1. Verificações Iniciais

### 1.1 Status do PM2
```bash
# Verificar se o processo está rodando
pm2 status

# Verificar logs do PM2
pm2 logs beta-back

# Reiniciar o processo se necessário
pm2 restart beta-back
```

### 1.2 Verificar se a aplicação está respondendo
```bash
# Testar diretamente na porta da aplicação
curl -I http://localhost:8080  # ou a porta configurada no .env

# Verificar se a porta está em uso
netstat -tlnp | grep :8080
lsof -i :8080
```

### 1.3 Verificar logs da aplicação
```bash
# Logs do PM2
pm2 logs beta-back --lines 100

# Logs do sistema
sudo journalctl -u nginx -f
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## 2. Configuração do Nginx

### 2.1 Verificar configuração do nginx
```bash
# Testar configuração
sudo nginx -t

# Verificar arquivo de configuração
sudo cat /etc/nginx/sites-available/seu-dominio
```

### 2.2 Exemplo de configuração nginx para o projeto
```nginx
server {
    listen 80;
    server_name seu-dominio.com;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name seu-dominio.com;
    
    # Certificados SSL (após certbot)
    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;
    
    # Configurações SSL recomendadas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Frontend (React)
    location / {
        root /caminho/para/frontend/build;
        try_files $uri $uri/ /index.html;
        
        # Headers de segurança
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # WebSocket para Socket.IO
    location /socket.io/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Arquivos estáticos do backend
    location /public/ {
        proxy_pass http://localhost:8080/public/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 3. Verificações de Ambiente

### 3.1 Variáveis de ambiente
```bash
# Verificar se o .env está configurado corretamente
cat backend/.env

# Verificar variáveis críticas
echo $PORT
echo $NODE_ENV
echo $DATABASE_URL
```

### 3.2 Verificar dependências
```bash
# No diretório backend
cd backend
npm install
npm run build

# Verificar se o arquivo dist/server.js existe
ls -la dist/
```

### 3.3 Verificar banco de dados
```bash
# Testar conexão com banco
cd backend
npm run db:migrate:status
```

## 4. Comandos de Diagnóstico

### 4.1 Verificar recursos do sistema
```bash
# Uso de memória
free -h

# Uso de CPU
top

# Espaço em disco
df -h

# Processos Node.js
ps aux | grep node
```

### 4.2 Testar conectividade
```bash
# Testar se a aplicação responde localmente
curl -v http://localhost:8080

# Testar através do nginx
curl -v https://seu-dominio.com/api/
```

## 5. Soluções Comuns

### 5.1 Reiniciar serviços
```bash
# Reiniciar PM2
pm2 restart all

# Reiniciar nginx
sudo systemctl restart nginx

# Verificar status
sudo systemctl status nginx
pm2 status
```

### 5.2 Verificar firewall
```bash
# Verificar se a porta está liberada
sudo ufw status

# Se necessário, liberar porta
sudo ufw allow 8080
```

### 5.3 Verificar permissões
```bash
# Verificar permissões dos arquivos
ls -la backend/dist/
ls -la frontend/build/

# Corrigir permissões se necessário
sudo chown -R www-data:www-data /caminho/do/projeto
sudo chmod -R 755 /caminho/do/projeto
```

## 6. Logs Detalhados

### 6.1 Habilitar logs detalhados no nginx
```nginx
# Adicionar no server block
error_log /var/log/nginx/error.log debug;
access_log /var/log/nginx/access.log;
```

### 6.2 Logs da aplicação Node.js
```bash
# Ver logs em tempo real
pm2 logs beta-back --lines 50 -f

# Ver logs de erro específicos
pm2 logs beta-back --err --lines 100
```

## 7. Checklist de Verificação

- [ ] PM2 está rodando (`pm2 status`)
- [ ] Aplicação responde na porta local (`curl localhost:8080`)
- [ ] Nginx está rodando (`sudo systemctl status nginx`)
- [ ] Configuração nginx está válida (`sudo nginx -t`)
- [ ] Certificados SSL estão válidos
- [ ] Firewall permite tráfego
- [ ] Variáveis de ambiente estão configuradas
- [ ] Banco de dados está acessível
- [ ] Arquivos de build existem
- [ ] Permissões estão corretas

## 8. Comandos de Emergência

```bash
# Reiniciar tudo
sudo systemctl restart nginx
pm2 restart all

# Verificar status
sudo systemctl status nginx
pm2 status

# Logs em tempo real
pm2 logs --lines 50
sudo tail -f /var/log/nginx/error.log
```
