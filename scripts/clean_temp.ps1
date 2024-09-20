<#
    TempCleanupUtilityWindows: Is a system maintenance tool for Windows, designed to automates the process 
	of clearing browser data by removing cache and cookies from Google Chrome and Mozilla Firefox. 
    Additionally, it cleans up temporary files and system directories such as Temp 
    and Prefetch to free up disk space and improve system responsiveness. 
    The utility ensures that it runs with administrative privileges for effective cleaning 
    and provides user-friendly feedback throughout the execution process.
    Copyright (C) 2024  Paulo Sebastian Spaciuk (Darukio)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

# Verificar si el script se está ejecutando como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Reiniciar el script con privilegios de administrador
    $newProcess = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    # Salir del script actual
    exit
}

# Limpiar caché y cookies de Google Chrome
function Clear-ChromeData {
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
    if (Test-Path $chromePath) {
        Write-Output "Limpiando datos de Google Chrome..."
        if (Test-Path "$chromePath\Cache") {
            Remove-Item "$chromePath\Cache" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$chromePath\Cookies") {
            Remove-Item "$chromePath\Cookies" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$chromePath\Network") {
            Remove-Item "$chromePath\Network\Cookies" -Force -ErrorAction SilentlyContinue
            Remove-Item "$chromePath\Network\Cookies-journal" -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Output "Google Chrome no está instalado."
    }
}

# Limpiar caché y cookies de Mozilla Firefox
function Clear-FirefoxData {
    $firefoxPaths = @(
        "$env:APPDATA\Mozilla\Firefox\Profiles",    # Roaming
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" # Local
    )

    foreach ($firefoxPath in $firefoxPaths) {
        if (Test-Path $firefoxPath) {
            Write-Output "Limpiando datos de Mozilla Firefox..."
            $profiles = Get-ChildItem -Path $firefoxPath -Directory
            foreach ($profile in $profiles) {
                $cachePath = Join-Path -Path $profile.FullName -ChildPath 'cache2'
                $cookiesPath = Join-Path -Path $profile.FullName -ChildPath 'cookies.sqlite'
                if (Test-Path $cachePath) {
                    Remove-Item $cachePath -Recurse -Force -ErrorAction SilentlyContinue
                }
                if (Test-Path $cookiesPath) {
                    Remove-Item $cookiesPath -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            Write-Output "Mozilla Firefox no está instalado."
        }
    }
}

# Limpiar archivos temporales
function Clear-TempFiles {
    Write-Output "Limpiando archivos temporales..."

    $tempPaths = @(
        "$env:WINDIR\Temp",
        "$env:TEMP",
        "$env:WINDIR\Prefetch"
        
    )
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            Write-Output "Eliminando archivos en $path..."
            try {
                Get-ChildItem -Path $path -Recurse -Force | ForEach-Object {
                    try {
                        Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
                    } catch {
                        #Write-Output "No se pudo eliminar $_.FullName: $_"
                    }
                }
            } catch {
                #Write-Output "No se pudo acceder a ${path}: $_"
            }
        } else {
            #Write-Output "La ruta $path no existe."
        }
    }
}

# Ejecutar las funciones
Clear-ChromeData
Clear-FirefoxData
Clear-TempFiles

# Pausar el script y esperar que el usuario presione una tecla
Write-Output "La limpieza ha finalizado. Presiona cualquier tecla para salir..."
[void][System.Console]::ReadKey($true)