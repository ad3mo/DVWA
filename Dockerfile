FROM php:8.2-apache

# Match upstream DVWA image: GD (JPEG/Freetype), mysqli + PDO MySQL, Apache rewrite (API .htaccess), ping (Command Injection lab).
RUN apt-get update && apt-get install -y --no-install-recommends \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libmariadb-dev \
    iputils-ping \
    git \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install gd mysqli pdo pdo_mysql \
    && a2enmod rewrite \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

COPY . /var/www/html/

RUN cd /var/www/html/vulnerabilities/api \
    && composer install --no-dev --no-interaction --optimize-autoloader

# Ensure writable config exists (same pattern as upstream Dockerfile).
RUN if [ ! -f config/config.inc.php ]; then \
      cp config/config.inc.php.dist config/config.inc.php; \
    fi

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
