# ESTÁGIO 1: Build (A "Cozinha")
FROM node:20-alpine AS builder

# Instala dependências do sistema necessárias para compilar módulos nativos
RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++ \
    build-base \
    cairo-dev \
    pango-dev \
    chromium \
    curl

# Instala o pnpm globalmente
RUN npm install -g pnpm@latest

WORKDIR /usr/src/flowise

# Copia apenas os ficheiros de configuração primeiro (otimização de cache)
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages ./packages

# 🛠️ CORREÇÃO 1: Instala dependências permitindo scripts de build (necessário p/ sharp, canvas, etc)
# O flag --no-frozen-lockfile ajuda se houver discrepâncias de versão
RUN pnpm install --no-frozen-lockfile

# 🛠️ CORREÇÃO 2: Build do projeto
# O aumento de memória ajuda o Turbo/TS a não crashar
ENV NODE_OPTIONS=--max-old-space-size=8192
RUN pnpm build

# ---------------------------------------------------------
# ESTÁGIO 2: Runner (O "Prato Pronto")
FROM node:20-alpine AS runner

WORKDIR /usr/src/flowise

# Instala apenas o pnpm para rodar o start
RUN npm install -g pnpm@latest

# Copia apenas o que é estritamente necessário do estágio de build
COPY --from=builder /usr/src/flowise /usr/src/flowise

# Instala o Chromium para o nó de Scraper/Puppeteer
RUN apk add --no-cache chromium
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Configurações de ambiente
ENV FLOWISE_USERNAME=admin
ENV FLOWISE_PASSWORD=admin
ENV PORT=3000

# Criar e usar utilizador não-root para segurança
RUN chown -R node:node /usr/src/flowise
USER node

EXPOSE 3000

CMD [ "pnpm", "start" ]