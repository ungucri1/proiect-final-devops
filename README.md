## Structura Proiectului
 - `/app/monitor` : [aplicatia de monitorizare si dockerfile]
 - `/app/monitor` : [aplicatia de backup si dockerfile]
 - `/compose` : [un compose care porneste ambele local sau remote via Ansible]
 - `/ansible` : [deploy pe VM (copiaza intregul repository si face compose up)]
 - `/jenkins` : [definiri de pipeline]

## Setup & Rulare
**1) Cerinte**
 - masina *host*
 - masina *target*
 - tool-uri necesare pe masina host:
       - `git`,`ansible`,`ssh`,`docker`
 - tool-uri necesare pe asina target:
       - docker si docker compose v2
       - user: `ansibleuser`
       - IMPORTANT: `ansibleuser` trebuie adaugat in grupul de `docker`, pentru a rula comenzi fara sudo.
 ```bash
sudo usermod -aG docker ansibleuser
```
**2) Config Ansible**
Editeaza `ansible/inventory.ini`:

```ini
[dockerhosts]
target ansible_host=192.168.1.195 ansible_user=ansibleuser
```

Cheia SSH publica a hostului trebuie sa fie in ~ansibleuser/.ssh/authorized_keys pe VM-ul target

Comanda de test:
 ```bash
ansible -i ansible/inventory.ini dockerhosts -m ping
```

**3) Rulare locala (pas optional)**
Din directorul proiectului rulam urmatoarele comenzi:
```bash
cd compose
docker compose up --build -d
docker compose ps
docker logs -n 50 monitorcontainer
docker logs -n 50 backup-container
```

**4) Deploy pe VM cu Ansible**
executam comanda:

```bash
ansible-playbook -i ansible/inventory.ini ansible/deploy-app.yml
```
Ce face:
- sterge orice versiune veche a proiectului pe target.
- creeaza structura `/home/ansibleuser/proiect-final/{compose,app}.`
- copiaza directoarele `compose/` si `app/` pe target.
- opreste containere vechi (daca exista).
- ruleaza `docker compose up --build -d` pe target.

Comenzi de verificare pe VM-ul target:

```bash
ssh ansibleuser@192.168.1.195
docker compose -f /home/ansibleuser/proiect-final/compose/docker-compose.yml ps
docker logs -n 50 monitorcontainer
docker logs -n 50 backup-container
ls -l /home/ansibleuser/proiect-final/backup
```

## CI/CD și Automatizari

Pipeline-uri

Avem cate unul pe fiecare componenta:

- pipeline_monitor_bash — folosește `jenkins/Jenkinsfile.bash`:
    - Lint shell: `bash -n app/monitor/monitor.sh`
    - SSH pe target => clone repo
    - Build imagine pe target cu context `app/monitor`:
     `docker build -t ungucri0103/monitor:latest -f app/monitor/Dockerfile app/monitor`
    - Login si push in Docker Hub.


- Pipeline_backup_python — `folosește jenkins/Jenkinsfile.python`:
    -Lint python: `python3 -m py_compile app/backup/backup.py`
    -Tests: `python3 -m unittest discover -s app/backup/tests -p "*.py" || echo "No tests found"`
    -SSH pe target => clone repo
    -Build imagine pe target cu context `app/backup`:
     `docker build -t ungucri0103/backup:latest -f app/backup/Dockerfile app/backup`
    -Login si push in Docker Hub.

- Credentiale in Jenkins
   - Github(deja configurat la job - credentiale Github)
   - Docker Hub: `parola-dockerhub`(user si parola)
   - SSH spre target: `target-ssh`(SSH user cu cheia privata)
     - `username: ansibleuser`
     - cheia privata folosita de Ansible
   - In Jenkins se foloseste pluginul SSH steps si binding de credentiale
     
 - Permisiuni & useri Jenkins
    - Realm: baza de date Jenkins
    - Matrix based security: user dedicat `userproiect` cu permisiuni minime pentru joburile proiectului(React/Build)
    - View dedicat "ProiectFinal" cu cele doua joburi incluse
      
  - Trigger
    - Poti porni manual fiecare pipeline
    - (Optional) `POLL SCM` daca vrei build la commit fara webhooks publice

## Depanare / erori cunoscute 

- `docker: not found` in Jenkins
  Nu rulam build pe Jenkins; rulam pe target prin SSH(solutia deja implementata)
- `permission denied /var/run/docker.sock` pe target
  Adauga ansibleuser in grupul docker si da reboot:

  ```bash
  sudo usermod -aG docker ansibleuser
  sudo reboot
  ```
- `COPY file ... not found` la build
  Contextul de build trebuie sa fie directorul in care exista fisierul copiat (De aceea folosim ` ...-f app/backup/Dockerfile app/backup` si `... -f app/monitor/Dockerfile/app/monitor`.)
- Unit tests
  Daca nu ai test, comanda din pipeline nu va pica buildul:

  ```bash

  python3 -m unittest discover -s app/backup/tests -p "*.py" || echo "No tests found"
   ```
- Compose "container name is already in use"
  In playbook exista task-uri care opresc containerele vechi inainte de compose up. Daca rulezi manual, sterge-le:

  ```bash

  docker rm -f backup-container monitorcontainer || true
   ```

  ## Comenzi utile

- Local din folderul compose:
 ```bash
  docker compose up --build -d
  docker compose ps
  docker logs -n 50 monitorcontainer
  docker logs -n 50 backup-container
  docker compose down
 ```
- Pe VM-ul target:
 ```bash
  ssh ansibleuser@192.168.1.195
  docker compose -f /home/ansibleuser/proiect-final/compose/docker-compose.yml up -d --build
  docker compose -f /home/ansibleuser/proiect-final/compose/docker-compose.yml ps
 ```

- Ansible:
 ```bash
  ansible -i ansible/inventory.ini dockerhosts -m ping
  ansible-playbook -i ansible/inventory.ini ansible/deploy-app.yml
 ```

- Resurse:
  - Docker: COPY & context - documentatia oficiala te ajuta sa eviti erorile de context
  - Ansible community.docker collection (pentru taskul de compose)
  - [Sintaxa Markdown](https://www.markdownguide.org/cheat-sheet/)
