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

# 🛠️ CORREÇÃO: Remova o tsconfig.json desta linha, já que ele não existe na raiz.
# Deixe o turbo.json com o curinga (*) para garantir que não quebre se ele também não estiver aí.
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.jso* ./

# Este comando abaixo já leva os tsconfig.json internos (components e server)
COPY packages ./packages

# ----------------------------------------------------------------
# 💡 DICA DE OURO: Se o build do Turbo reclamar que falta um tsconfig na raiz,
# você pode criar um "fake" apenas para satisfazer o compilador:
RUN echo '{"compilerOptions": {"composite": true}}' > tsconfig.json

# Agora instale e builde
RUN pnpm install --no-frozen-lockfile
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