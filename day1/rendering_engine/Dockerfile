FROM debian:stable-slim AS build-env

RUN apt-get update && apt-get install -y     build-essential     cmake     git     curl     unzip     && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/microsoft/vcpkg.git .vcpkg-root &&     ./.vcpkg-root/bootstrap-vcpkg.sh

ENV PATH="/app/.vcpkg-root:/home/systemdr/.local/bin:/home/systemdr/.cursor-server/bin/7b9c34466f5c119e93c3e654bb80fe9306b6cc70/bin/remote-cli:/home/systemdr/.local/bin:/home/systemdr/.nvm/versions/node/v22.21.1/bin:/home/systemdr/.cursor-server/bin/7b9c34466f5c119e93c3e654bb80fe9306b6cc70/bin/remote-cli:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/WINDOWS/system32:/mnt/c/WINDOWS:/mnt/c/WINDOWS/System32/Wbem:/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/:/mnt/c/WINDOWS/System32/OpenSSH/:/mnt/c/ProgramData/chocolatey/bin:/mnt/c/Program Files/Docker/Docker/resources/bin:/mnt/c/Program Files/dotnet/:/mnt/c/Users/syste/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/syste/AppData/Local/Programs/cursor/resources/app/bin:/mnt/c/Users/syste/AppData/Local/Programs/Microsoft VS Code/bin:/snap/bin:/home/systemdr/.dotnet/tools:/home/systemdr/go/bin:/home/systemdr/go/bin"

COPY CMakeLists.txt ./
COPY src ./src

RUN ./.vcpkg-root/vcpkg install spdlog --triplet x64-linux &&     cmake -B build -S .           -DCMAKE_TOOLCHAIN_FILE=./.vcpkg-root/scripts/buildsystems/vcpkg.cmake &&     cmake --build build -j8

FROM debian:stable-slim AS run-env

COPY --from=build-env /app/build/app /usr/local/bin/app

COPY --from=build-env /app/.vcpkg-root/installed/x64-linux/lib /usr/local/lib

ENV LD_LIBRARY_PATH="/usr/local/lib:"

CMD ["/usr/local/bin/app"]
