#!/bin/sh
set -e

apk add --no-cache openssl

BASE=/pki
ROOT=$BASE/root
ISSUING=$BASE/issuing
CERTS=$BASE/certs

mkdir -p "$ROOT" "$ISSUING" "$CERTS"

echo " Iniciando PKI local..."

####################################
# ROOT CA
####################################
if [ ! -f "$ROOT/ca.crt" ]; then
  echo " Creando Root CA"
  openssl genrsa -out "$ROOT/ca.key" 4096
  openssl req -x509 -new -nodes \
    -key "$ROOT/ca.key" \
    -sha256 -days 3650 \
    -out "$ROOT/ca.crt" \
    -subj "/C=EC/ST=Pichincha/L=Quito/O=LocalDev/OU=Root/CN=Local Root CA"
else
  echo "✔ Root CA existente"
fi

####################################
# ISSUING CA
####################################
if [ ! -f "$ISSUING/issuing.crt" ]; then
  echo " Creando Issuing CA"
  openssl genrsa -out "$ISSUING/issuing.key" 4096

  openssl req -new \
    -key "$ISSUING/issuing.key" \
    -out "$ISSUING/issuing.csr" \
    -subj "/C=EC/ST=Pichincha/L=Quito/O=LocalDev/OU=Issuing/CN=Local Issuing CA"

  cat > "$ISSUING/ext.cnf" <<EOF
basicConstraints=CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

  openssl x509 -req \
    -in "$ISSUING/issuing.csr" \
    -CA "$ROOT/ca.crt" \
    -CAkey "$ROOT/ca.key" \
    -CAcreateserial \
    -out "$ISSUING/issuing.crt" \
    -days 1825 -sha256 \
    -extfile "$ISSUING/ext.cnf"
else
  echo "Issuing CA existente"
fi

####################################
# WILDCARD CERTIFICATES
####################################
TLDs="dev local test def"

for TLD in $TLDs
do
  DIR="$CERTS/wildcard-$TLD"
  mkdir -p "$DIR"

  if [ ! -f "$DIR/fullchain.crt" ]; then
    echo " Generando *.${TLD}"

    openssl genrsa -out "$DIR/privkey.key" 2048

    openssl req -new \
      -key "$DIR/privkey.key" \
      -out "$DIR/wildcard.csr" \
      -subj "/CN=*.$TLD"

    cat > "$DIR/ext.cnf" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt

[alt]
DNS.1=*.$TLD
EOF

    openssl x509 -req \
      -in "$DIR/wildcard.csr" \
      -CA "$ISSUING/issuing.crt" \
      -CAkey "$ISSUING/issuing.key" \
      -CAcreateserial \
      -out "$DIR/cert.crt" \
      -days 825 -sha256 \
      -extfile "$DIR/ext.cnf"

    cat "$DIR/cert.crt" "$ISSUING/issuing.crt" > "$DIR/fullchain.crt"
    rm "$DIR/cert.crt" "$DIR/wildcard.csr" "$DIR/ext.cnf"
  else
    echo "✔ *.${TLD} existente"
  fi
done

echo "PKI local lista"
