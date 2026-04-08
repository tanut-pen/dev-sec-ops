mkdir local-acme-lab && cd local-acme-lab

# โหลด Root CA จำลองของ Pebble
curl -o pebble.minica.pem https://raw.githubusercontent.com/letsencrypt/pebble/master/test/certs/pebble.minica.pem

# สร้างไฟล์ว่างสำหรับเก็บ Certificate และกำหนดสิทธิ์ (Traefik บังคับใช้ chmod 600)
touch acme.json && chmod 600 acme.json