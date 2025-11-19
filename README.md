# Docker AI workspace
Docker container providing a complete Python environment with JupyterLab and an integrated SSH server.

## Features
- JupyterLab
- SSH server for remote access and IDE integration (e.g., Zed, VSCode)

## Usage
1. Clone the repository:
   ```bash
   git clone https://github.com/ArnoJoosen/docker_AI_workspace.git
   ```
2. Navigate to the project directory:
   ```bash
   cd docker_AI_workspace
   ```
3. Copy .env.example to .env and modify it as needed:
   ```bash
   cp .env.example .env
   ```
4. Run the docker compose command to start the container you have 3 options:
  - For Cuda enabled container (NVIDIA GPU required):
    ```bash
    docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up --build
    ```
  - For AMD GPU enabled container (AMD GPU required):
    ```bash
    docker-compose -f docker-compose.yml -f docker-compose.rocm.yml up --build
    ```
  - For CPU only container:
    ```bash
    docker-compose -f docker-compose.yml -f docker-compose.cpu.yml up --build
    ``
5. Access JupyterLab at `http://localhost:8888` use the token provided in .env file.
6. Access SSH server at `localhost:2222` with username `user` and password `password` or use SSH key authentication defined in .env file.
