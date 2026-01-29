# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview
This repository contains deployment scripts and documentation for deploying **Moltbot** on **FNNAS (Feiniu NAS/fnOS)**. It is a wrapper/utility project, not the Moltbot application source code itself.

The core logic involves cloning the official Moltbot repository, patching configurations for the Chinese network environment (Docker Hub restrictions), and automating the setup of containers and skills.

## Core Commands

### Deployment
*   **Run Automated Deployment**: `sudo ./deploy.sh`
    *   Requires `sudo` privileges.
    *   Interactive script: asks for Node image tag and confirmation.
    *   Target directory: `/vol1/moltbot` (Standard FNNAS storage path).

### Manual Operations (within `/vol1/moltbot` after cloning)
*   **Build Image**: `sudo docker build -t moltbot:local .`
*   **Generate Token/Onboard**: `sudo docker compose --env-file .env run --rm moltbot-cli onboard`
*   **Start Services**: `sudo docker compose up -d`
*   **View Logs**: `sudo docker compose logs -f`

## Architecture & Workflow

### `deploy.sh` Logic
1.  **Environment Check**: Verifies root privileges and `/vol1` directory existence.
2.  **Code Retrieval**: Clones `https://github.com/moltbot/moltbot.git` if not present.
3.  **Image Adaptation**:
    *   Asks user for local Node image tag (default: `node:25.5.0-bookworm`).
    *   Patches `Dockerfile` to use this local base image (bypassing registry pull issues).
    *   Injects `corepack` installation commands.
4.  **Configuration Injection**:
    *   Generates `docker-compose.override.yml` to map `./skills` -> `/app/skills`.
    *   Sets up environment variables for Gateway and CLI.
5.  **Skill Installation**: Uses a temporary container to run `clawdhub install` for default skills (tavily, github, summarize, weather).
6.  **Launch**: Executes `docker compose up -d`.

### Directory Structure
*   `deploy.sh`: Main automation script.
*   `README.md`: Comprehensive guide for users (Automated vs Manual).
*   `images/`: Screenshots used in the README.

## Development Constraints
*   **Target OS**: Linux (specifically FNNAS/Debian).
*   **Network**: Assumes restricted access to Docker Hub; relies on locally pulled images or accelerated mirrors.
*   **Pathing**: Hardcoded to `/vol1/moltbot` in scripts for FNNAS compatibility.
