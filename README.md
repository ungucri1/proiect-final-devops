## Structura Proiectului

/app/monitor - aplicatia de monitorizare si dockerfile
/app/monitor - aplicatia de backup si dockerfile
/compose - un compose care porneste ambele local sau remote via Ansible
/ansible - deploy pe VM (copiaza intregul repository si face compose up)
/jenkins - definiri de pipeline

## Setup & Rulare
#1) Cerinte
 - masina host
 - masina target
 - tool-uri necesare pe masina host:
       - git,ansible,ssh,docker
 - tool-uri necesare pe asina target:
       - docker si docker compose v2
       - user: ansibleuser
       - IMPORTANT: ansibleuser trebuie adaugat in grupul de docker, pentru a rula comenzi fara sudo.(sudo usermod -aG docker ansibleuser)

#2) Config Ansible
Editeaza ansible/inventory.ini:
[dockerhosts]
target ansible_host=192.168.1.195 ansible_user=ansibleuser
Cheia SSH publica a hostului trebuie sa fie in ~ansibleuser/.ssh/authorized_keys pe VM-ul target
Comanda de test: ansible -i ansible/inventory.ini dockerhosts -m ping

#3) Rulare locala (pas optional)
Din directorul proiectului rulam urmatoarele comenzi:
cd compose
docker compose up --build -d
docker compose ps
docker logs -n 50 monitorcontainer
docker logs -n 50 backup-container

#4) Deploy pe VM cu Ansible
executam comanda:
ansible-playbook -i ansible/inventory.ini ansible/deploy-app.yml
Ce face:
- sterge orice versiune veche a proiectului pe target.
- creeaza structura /home/ansibleuser/proiect-final/{compose,app}.
- copiaza directoarele compose/ si app/ pe target.
- opreste containere vechi (daca exista).
- ruleaza docker compose up --build -d pe target.











