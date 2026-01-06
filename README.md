## Propósito del proyecto local-dev-proxy

HTTPS local rápido para proyectos pequeños

Proyectos pequeños / medianos

APIs locales

Webhooks (Stripe, PayPal, WhatsApp, etc.)

Frontends simples

Backends en Docker o fuera de Docker

HTTPS obligatorio en local

* Dominios tipo:

* api.dev

* webhook.local

* auth.test

* miapp.dev

Problemas que resuelve 

| Problema                     | Solución               |
| ---------------------------- | ---------------------- |
| Webhooks requieren HTTPS     | ✔ Certificados locales |
| No quiero Let's Encrypt      | ✔ PKI propia           |
| Muchos dominios locales      | ✔ Wildcard cert        |
| No tocar `/etc/hosts`        | ✔ dnsmasq              |
| Configuración simple         | ✔ Nginx Proxy Manager  |
| Reutilizable entre proyectos | ✔ Proxy central        |




# Entorno Local  para HTTPS en desarrollo (Docker + NPM + PKI + DNS)


Este proyecto permite crear un **entorno de desarrollo local profesional**, con:

* Dominios locales (`.dev`, `.local`, `.test`, `.def`)
* HTTPS real con certificados SSL propios (sin Let's Encrypt)
* Reverse proxy con **Nginx Proxy Manager (NPM)**
* Resolución DNS local automática con **dnsmasq**
* Arquitectura escalable para múltiples proyectos Docker

---

##  Estructura del proyecto

```text
pki-local/
├── docker-compose.yml
├── README.md
│
├── dnsmasq/
│   └── dnsmasq.conf
│
├── nginx-proxy-manager/
│   ├── data/
│   └── letsencrypt/
│
├── pki/
│   ├── generate.sh
│   ├── root/
│   │   ├── 
│   │   └── 
│   ├── issuing/
│   │   ├── 
│   │   └── 
│   └── certs/
│       ├── wildcard-dev/
│       │   ├── 
│       │   └── 
│       ├── wildcard-local/
│       ├── wildcard-test/
│       └── wildcard-def/
```

---

##  Requisitos

* Docker
* Docker Compose
* Windows / Linux / macOS
* Permisos de administrador (para DNS)

---

##  Conceptos clave (IMPORTANTE)

###  ¿Por qué no usamos Let's Encrypt?

* Let's Encrypt **NO funciona en local**
* Requiere dominios públicos
* No sirve para `.dev`, `.local`, `.test`

 En local se usa **PKI propia**

---

### 🔹 ¿Cómo funciona el sistema?

1. **dnsmasq**

   * Resuelve `*.dev`, `*.local`, etc → `127.0.0.1`

2. **PKI local**

   * Crea una CA Root
   * Crea una CA Issuing
   * Genera certificados wildcard

3. **Nginx Proxy Manager**

   * Recibe tráfico HTTPS
   * Redirige a contenedores por nombre

4. **Apps Docker**

   * Se conectan a la red compartida
   * No exponen puertos

---

##  Paso 1 — Crear red compartida (UNA VEZ)

```bash
docker network create proxy-net
```

Esta red será usada por:

* Nginx Proxy Manager
* Todas las apps

---

##  Paso 2 — Configuración DNS (dnsmasq)

###  `dnsmasq/dnsmasq.conf`

```conf
address=/.test/127.0.0.1
address=/.local/127.0.0.1
address=/.dev/127.0.0.1
address=/.def/127.0.0.1

listen-address=0.0.0.0
bind-interfaces
```

 IMPORTANTE:

* Esto **solo afecta al contenedor dnsmasq**
* Para que tu PC lo use, debes configurar tu DNS

---

##  Paso 3 — Configurar DNS en el sistema (Windows)

### Opción recomendada

* DNS preferido: `127.0.0.1`
* DNS alternativo: `1.1.1.1`

> IPv6 debe estar desactivado o sin DNS

---

##  Paso 4 — Levantar infraestructura base

```bash
docker compose up -d
```

Esto levanta:

* PKI (una sola vez)
* dnsmasq
* Nginx Proxy Manager

---

##  Paso 5 — Instalar la CA Root en el sistema

Archivo:

```
pki/root/ca.crt
```

### En Windows:

1. Doble clic → Instalar certificado
2. Equipo local
3. Entidades de certificación raíz de confianza

 SIN ESTO, el navegador marcará HTTPS como inseguro

---

##  Paso 6 — Acceder a Nginx Proxy Manager

```
http://localhost:81
```

Credenciales por defecto:

```
Email: admin@example.com
Password: changeme
```

---

##  Paso 7 — Importar certificados wildcard

En **SSL Certificates → Add SSL Certificate → Custom**:

Para cada wildcard:

| Campo           | Archivo         |
| --------------- | --------------- |
| Certificate Key | `privkey.key`   |
| Certificate     | `fullchain.crt` |

Ejemplo:

```
wildcard-dev/*
wildcard-test/*
```

---

##  Paso 8 — Crear un Proxy Host

Ejemplo: `sgcec.dev`

### DETAILS

| Campo            | Valor       |
| ---------------- | ----------- |
| Domain           | `sgcec.dev` |
| Scheme           | `http`      |
| Forward Hostname | `sgcec_app` |
| Forward Port     | `80`        |
| Websockets       | ✅           |

### SSL

* Enable SSL
* Force SSL
* HTTP/2
* Certificado wildcard correspondiente

---

##  Paso 9 — Conectar apps a la red proxy

### docker-compose.yml de una app

```yaml
services:
  app:
    image: sgcec-app
    container_name: sgcec_app
    networks:
      - proxy-net

networks:
  proxy-net:
    external: true
```

 No exponer puertos

---

##  Verificación

```bash
ping sgcec.dev
```

Debe responder:

```
127.0.0.1
```

En navegador:

```
https://sgcec.dev
```

---

##  Errores comunes

### 502 Bad Gateway

* App no está en `proxy-net`
* Hostname incorrecto

### DNS_PROBE_POSSIBLE

* DNS del sistema mal configurado
* IPv6 activo

### HTTPS inseguro

* CA Root no instalada

---

## Resultado final

✔ Dominios locales
✔ HTTPS válido
✔ Certificados wildcard
✔ Sin puertos abiertos
✔ Arquitectura escalable

---

##  Recomendación final

Este entorno es ideal para:

* Microservicios
* APIs locales
* Frontend + Backend
* Desarrollo profesional

---


