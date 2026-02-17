# OpenGL Context Demo — Implementation Guide

Step-by-step guide to build, run, and use this project.

---

## 1. Prerequisites

Install these on your system (Linux example):

```bash
# Build tools
sudo apt-get update
sudo apt-get install -y build-essential cmake git

# vcpkg bootstrap (needed to install vcpkg)
sudo apt-get install -y curl zip unzip tar

# OpenGL/GLFW build dependencies (needed for glfw3)
sudo apt-get install -y libxinerama-dev libxcursor-dev xorg-dev libglu1-mesa-dev pkg-config

# Optional: headless/dashboard demo (virtual display)
sudo apt-get install -y xvfb

# Python 3 (for dashboard server)
# Usually pre-installed; if not: sudo apt-get install -y python3
```

---

## 2. Why vcpkg?

This project uses **vcpkg** to manage C++ dependencies:

- **GLFW** — window and input (OpenGL context, keyboard/mouse).
- **GLAD** — OpenGL function loader.

vcpkg provides:

- **Versioned, repeatable builds** — same versions of glfw3 and glad on every machine.
- **CMake integration** — `find_package(glfw3)`, `find_package(glad)` and correct link flags.
- **No manual download** — dependencies are fetched and built (or restored from cache) automatically.

Without vcpkg you would have to download GLFW and GLAD yourself, set include/lib paths, and keep them in sync with the project.

---

## 3. Installing vcpkg

You can either let `start.sh` install it for you, or install it yourself.

### Option A: Let start.sh install vcpkg (recommended)

On first run, if vcpkg is not found, `start.sh` can:

1. Clone vcpkg into the parent directory (`../vcpkg`).
2. Run the vcpkg bootstrap script.
3. Install `glfw3` and `glad` for the current triplet (e.g. `x64-linux`).

Ensure **git**, **curl**, **zip**, **unzip**, and **tar** are installed (see Prerequisites), then run:

```bash
./start.sh
```

If the auto-install fails (e.g. missing tools or network), follow Option B.

### Option B: Manual vcpkg install

1. **Clone vcpkg** (e.g. in the parent of this project):

   ```bash
   cd "$(dirname "$0")/.."
   git clone https://github.com/microsoft/vcpkg.git vcpkg
   cd vcpkg
   ```

2. **Bootstrap vcpkg** (builds the `vcpkg` binary):

   ```bash
   ./bootstrap-vcpkg.sh
   ```

3. **Install project dependencies**:

   ```bash
   ./vcpkg install glfw3 glad --triplet x64-linux
   ```

   On macOS use `x64-osx`; on Windows use `x64-windows` (or the triplet that matches your toolchain).

4. **Return to the project** and run:

   ```bash
   cd OpenGLContextDemo
   ./start.sh
   ```

If you install vcpkg in a different path, set **VCPKG_ROOT** before building:

```bash
export VCPKG_ROOT=/path/to/vcpkg
./start.sh
```

---

## 4. Build the project

From the **project directory** (where `start.sh` and `CMakeLists.txt` live):

```bash
./start.sh
```

`start.sh` will:

- Use vcpkg (from `../vcpkg`, or `VCPKG_ROOT`, or `PATH`).
- Configure with CMake and the vcpkg toolchain.
- Build the `OpenGLContextDemo` executable into `bin/`.

To build again after code changes, run `./start.sh` again (it will rebuild if the binary is missing or you can delete `bin/OpenGLContextDemo` to force a full rebuild).

---

## 5. Run the demo

- **With a display:**  
  `./start.sh` builds (if needed), runs the OpenGL window, then starts the dashboard. Close the demo window to continue; the dashboard stays running.

- **Headless (no display, e.g. SSH or CI):**  
  If `DISPLAY` is not set, `start.sh` uses **xvfb** (virtual display) and runs the demo for a few seconds, then exits. Install `xvfb` if you see a message about it.

- **Dashboard:**  
  After the demo run, open:  
  **http://localhost:8769/dashboard.html**  
  to see metrics and run the demo from the browser (“Run ./start.sh”).

---

## 6. Stop services

```bash
./stop.sh
```

Stops the dashboard server and any running OpenGLContextDemo process.

---

## 7. Cleanup (optional)

```bash
./cleanup.sh
```

- Stops project services (same as `stop.sh`).
- Stops Docker containers and prunes unused Docker resources (if Docker is available).
- Removes local artifacts (e.g. `node_modules`, `venv`, `.pytest_cache`, `*.pyc`, `Istio`, `vendor`, `*.rr`) from the project directory.

Use this to free disk space or reset the environment.

---

## 8. Run tests

```bash
./run_tests.sh
```

Checks that the dashboard metrics file exists and (if the app is built) that the binary runs and prints OpenGL info.

---

## 9. Project layout (reference)

| Path               | Purpose                          |
|--------------------|----------------------------------|
| `bin/`             | Built executable (generated)     |
| `build/`           | CMake build tree (generated)      |
| `src/main.cpp`     | OpenGL 4.6 / 3.3 context demo    |
| `CMakeLists.txt`   | CMake + vcpkg config             |
| `start.sh`         | Build, run demo, start dashboard  |
| `stop.sh`          | Stop dashboard and app           |
| `cleanup.sh`       | Stop services, Docker prune, rm artifacts |
| `server.py`        | Dashboard HTTP server            |
| `dashboard.html`  | Dashboard UI                     |
| `metrics.json`     | Run metrics (updated by start.sh) |
| `run_tests.sh`     | Basic tests                      |
| `IMPLEMENTATION_GUIDE.md` | This guide              |

---

## 10. Troubleshooting

| Issue | What to do |
|-------|-------------|
| **vcpkg not found** | Install prerequisites (git, curl, zip, unzip, tar), then run `./start.sh` again so it can install vcpkg, or install vcpkg manually (see §3 Option B). |
| **Failed to create GLFW window** | No display: install `xvfb` and run `./start.sh` again (headless path uses xvfb). Or set `DISPLAY` if you have an X server. |
| **Build fails (glfw3/glad)** | Ensure vcpkg is bootstrapped and run: `../vcpkg/vcpkg install glfw3 glad --triplet x64-linux` (or set `VCPKG_ROOT` and run `./start.sh`). |
| **Dashboard not loading** | Run `./start.sh`; then open http://localhost:8769/dashboard.html. If port 8769 is in use, set `DASHBOARD_PORT` to another port. |
