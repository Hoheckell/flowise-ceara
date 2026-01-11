# ESTÁGIO 1: Build
FROM node:20-alpine AS builder

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

RUN npm install -g pnpm@latest

WORKDIR /usr/src/flowise

# 🛠️ CORREÇÃO: Copiar TODOS os arquivos de configuração da raiz
# Precisamos do turbo.json, tsconfig.json e as definições do workspace
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.json tsconfig.json ./

# Copia as pastas dos pacotes
COPY packages ./packages

# Instala as dependências
RUN pnpm install --no-frozen-lockfile

# Configuração de memória e Build
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