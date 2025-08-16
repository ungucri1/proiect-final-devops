#!/bin/bash

INTERVAL=${SYSTEM_INTERVAL:-5}
LOG_FILE="system-state.log"


get_system_info() {
	echo "Sistem monitorizat la $(date '+%Y-%m-%d %H:%M:%S')"
	
	echo "CPU"
	top -bn1 | grep "Cpu(s)" | awk '{print "CPU utilizat: " $2 + $4 "%"}'

	echo "RAM"
	free -h | awk '/Mem:/ {printf("folosita: %s / Total: %s (%.0f%%)\n", $3, $2, ($3/$2)*100)}'

	echo "Partitions"
	df -h / | awk 'NR==2 {print "folosita: "$3 ", Total: " $2 ", Utilizare: " $5}'

	echo "Procese active"
	ps -e --no-headers | wc -l | awk '{print "procese active: " $1}'

}


if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
	echo "[Error] SYSTEM_INTERVAL trebuie sa fie un numar intreg (pozitiv)." >&2
	exit 1
fi

while true; do
	get_system_info > "$LOG_FILE"
	echo "[INFO] Fisierul $LOG_FILE a fost actualizat."
	sleep "$INTERVAL"
done