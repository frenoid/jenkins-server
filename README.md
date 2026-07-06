# Jenkins Server - Bare Metal Homelab Setup

## Introduction

This repository contains the configuration files, Dockerfile, and run scripts for deploying Jenkins 2.555.3 on a bare metal server in a homelab environment.

It uses a Docker-in-Docker (DinD) approach with TLS-encrypted communication between Jenkins and the Docker daemon. The setup includes:

- **Jenkins Master** with Blue Ocean UI (`run-jenkins-blueocean.sh`)
- **Docker DinD** service for build agents (`run-jenkins-docker.sh`)
- **Custom Dockerfile** with pre-installed plugins: Blue Ocean, Docker Workflow, and JSON Path API
- **Persistent storage** under `/mnt/data/jenkins/` for Jenkins home and TLS certificates
- **Security** enabled with Jenkins built-in user database, signup disabled, and anonymous access denied

### Key Configuration

| Setting              | Value                  |
|----------------------|------------------------|
| Jenkins Version      | 2.555.3 (JDK 21)       |
| Executors            | 8                      |
| Agent Port           | 50000                  |
| HTTP Port            | 8080                   |
| Docker TLS Port      | 2376                   |
| Data Directory       | /mnt/data/jenkins/data |
| Certs Directory      | /mnt/data/jenkins/certs|

---

## Prerequisites

- A bare metal server (Ubuntu/Debian recommended)
- Docker installed and running
- Docker Compose (optional, for alternative setup)
- Ports `8080`, `50000`, and `2376` available

---

## Step-by-Step Installation

### Step 1 — Create Persistent Directories

Create the directories for Jenkins data and TLS certificates:

```bash
sudo mkdir -p /mnt/data/jenkins/data
sudo mkdir -p /mnt/data/jenkins/certs
sudo chmod 777 /mnt/data/jenkins/data
sudo chmod 777 /mnt/data/jenkins/certs
```

### Step 2 — Create the Docker Network

The Jenkins and DinD containers communicate over a shared Docker network:

```bash
docker network create jenkins
```

### Step 3 — Build the Custom Jenkins Image

Build the Docker image from the provided Dockerfile (installs Docker CLI and required plugins):

```bash
cd /path/to/jenkins-server
docker build -t frenoid/jenkins-blueocean:2.555.3-jdk21 .
```

### Step 4 — Start the Docker-in-Docker Service

Run the `docker:dind` container first. This exposes the Docker API over TLS on port 2376:

```bash
bash run-jenkins-docker.sh
```

This container:
- Mounts `/mnt/data/jenkins/certs` for TLS certificate sharing
- Mounts `/mnt/data/jenkins/data` as Jenkins home
- Runs with `--privileged` and `overlay2` storage driver

### Step 5 — Start the Jenkins Blue Ocean Container

With DinD running, start the Jenkins master:

```bash
bash run-jenkins-blueocean.sh
```

This container:
- Connects to the Docker daemon at `tcp://docker:2376` over TLS
- Publishes Jenkins UI on port **8080**
- Exposes agent port **50000**
- Uses `--restart=on-failure` for automatic recovery

### Step 6 — Retrieve the Initial Admin Password

After Jenkins starts, extract the auto-generated password:

```bash
docker exec jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 7 — Complete Jenkins Setup in the Browser

1. Open `http://<your-server-ip>:8080` in your browser
2. Paste the initial admin password from Step 6
3. Choose "Install suggested plugins" (Blue Ocean, Docker, and JSON Path are pre-installed)
4. Create your first admin user
5. Complete the setup wizard

---

## File Reference

| File                     | Description                                           |
|--------------------------|-------------------------------------------------------|
| `Dockerfile`             | Custom Jenkins image with Docker CLI and plugins      |
| `config.xml`             | Jenkins master configuration                          |
| `run-jenkins-docker.sh`  | Launches Docker-in-Docker container with TLS          |
| `run-jenkins-blueocean.sh` | Launches Jenkins Blue Ocean with persistent storage |

---

## Useful Commands

```bash
# Check container status
docker ps

# View Jenkins logs
docker logs jenkins-blueocean

# View DinD logs
docker logs jenkins-docker

# Stop both containers
docker stop jenkins-blueocean jenkins-docker

# Remove containers (data persists on disk)
docker rm jenkins-blueocean jenkins-docker
```

## Troubleshooting

- **Port 8080 already in use**: Stop the conflicting service or change the port mapping in `run-jenkins-blueocean.sh`.
- **Container fails to start**: Check logs with `docker logs <container-name>` and verify TLS certs exist in `/mnt/data/jenkins/certs`.
- **Permission denied on data directory**: Ensure `/mnt/data/jenkins/data` has proper write permissions for the Jenkins user (UID 1000).