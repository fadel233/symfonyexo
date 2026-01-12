# ========= Base commune =========
FROM dunglas/frankenphp:1-php8.3-alpine AS base
WORKDIR /app

# Paquets système (intl, zip, gd, etc. si besoin)
RUN apk add --no-cache \
    icu-dev oniguruma-dev libzip-dev zlib-dev libpng libpng-dev git bash \
 && docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) intl pdo_mysql opcache \
 && apk del libpng-dev || true

# Caddyfile pour FrankenPHP
COPY ./Caddyfile /etc/caddy/Caddyfile

# >>> AJOUTER COMPOSER <
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# ========= Image Dev =========
FROM base AS dev
ENV APP_ENV=dev
EXPOSE 8080
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]

# ========= Image Production =========
FROM base AS prod
ENV APP_ENV=prod

# Copier le code
COPY ./app /app

# Installer les dépendances sans dev
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Créer les dossiers nécessaires et donner les permissions
RUN mkdir -p var/cache var/log && \
    chown -R www-data:www-data var/

# Vider le cache en production
RUN php bin/console cache:clear --env=prod --no-debug

EXPOSE 8080
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
