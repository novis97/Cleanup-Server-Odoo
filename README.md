Bersih-bersih instalasi lama (tanpa reinstall VPS)
Skrip otomatis agar Anda bisa reset tanpa format VPS. Ada 3 mode: safe, nuke, dan purge-nginx.

Cara pakai
# 1) Safe clean: hentikan & hapus container + network,
#    TAPI simpan volumes (database & filestore), image, dan folder ~/odoo18
sudo bash cleanup_odoo18.sh safe

# 2) Nuke (BERSIHKAN TOTAL): hapus SEMUA container, network, image, volumes (DB/filestore),
#    unit systemd, dan folder ~/odoo18  → DATA HILANG PERMANEN
sudo bash cleanup_odoo18.sh nuke

# 3) Kalau sempat pasang Nginx di HOST (bentrok port 80/443), hapus sekalian:
sudo bash cleanup_odoo18.sh purge-nginx
	
Rekomendasi:
		○ Jalankan safe dulu. Kalau mau benar-benar mulai dari nol, pastikan sudah backup (./backup.sh <dbname>) lalu jalankan nuke.
Yang dibersihkan oleh skrip
	• Systemd unit odoo18-multi.service (stop + disable + remove).
	• Containers: odoo18_postgres, odoo18_sand1/2/3, odoo18_nginx.
	• Network: odoo_network.
	• Volumes (hanya mode nuke): odoo18_postgres_data, odoo18_sand1/2/3_filestore.
	• Image (mode nuke): odoo18-custom:latest.
	• Folder (mode nuke): ~/odoo18.
	• UFW: hapus rules 80/443/8069–8071 (abaikan error jika rule tidak ada).
	• Nginx host (opsional purge-nginx): apt purge nginx* + hapus /etc/nginx.

Alur “bersih → pasang ulang” yang aman
	1. (Opsional) Backup database lama:
cd ~/odoo18
./backup.sh nama_database
	
 2. Bersihkan:
sudo bash cleanup_odoo18.sh safe   # atau nuke jika ingin kosong total
