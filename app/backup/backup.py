#!/usr/bin/env python3

import os
import time
import shutil
import hashlib
from datetime import datetime


INTERVAL = int(os.getenv("BACKUP_INTERVAL", 5))
BACKUP_DIR = os.getenv("BACKUP_DIR", "backup")
SOURCE_FILE = "system-state.log"
LAST_HASH = None

os.makedirs(BACKUP_DIR, exist_ok=True)


def get_file_hash(path):
	try:
		with open(path, "rb") as f:
			return hashlib.sha256(f.read()).hexdigest()
	except FileNotFoundError:
		return None 

def make_backup():
	global LAST_HASH
	current_hash = get_file_hash(SOURCE_FILE)

	if current_hash is None:
		print("[WARN] Fisierul de monitorizare nu exista")
		return

	if current_hash == LAST_HASH:
		print("[INFO] Fisier nemodificat. Nu se face backup")
		return



	timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
	backup_filename = f"{SOURCE_FILE.replace('.log','')}_backup_{timestamp}.log"
	backup_path = os.path.join(BACKUP_DIR, backup_filename)

	try:
		shutil.copy2(SOURCE_FILE, backup_path)
		print(f"[INFO] backup creat: {backup_path}")
		LAST_HASH = current_hash
	except Exception as e:
		print(f"[ERROR] eroare la crearea backup-ului: {e}")


if INTERVAL <= 0:
	print("[ERROR] BACKUP_INTERVAL trebuie sa fie un numar pozitiv.")
	exit(1)

print(f"[START] pornit script backup. Interval: {INTERVAL} sec. Director: {BACKUP_DIR}")
while True:
	try:
		make_backup()
	except Exception as err:
		print(f"[ERROR] a aparut o eroare neasteptata: {err}")
	time.sleep(INTERVAL)