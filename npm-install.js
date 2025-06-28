#!/usr/bin/env node

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

console.log('🚀 Instalando Asis-coder...');

// Detectar sistema operativo
const isWindows = os.platform() === 'win32';
const isMacOS = os.platform() === 'darwin';
const isLinux = os.platform() === 'linux';

try {
    // Obtener la ruta del paquete instalado
    const packagePath = __dirname;
    const coderScript = path.join(packagePath, 'coder.sh');
    
    // Verificar que el script principal existe
    if (!fs.existsSync(coderScript)) {
        console.error('❌ Error: No se encontró coder.sh');
        process.exit(1);
    }
    
    if (isWindows) {
        console.log('🪟 Sistema Windows detectado');
        installWindows(packagePath, coderScript);
    } else {
        console.log(`🐧 Sistema ${isMacOS ? 'macOS' : 'Linux'} detectado`);
        installUnix(packagePath, coderScript);
    }
    
    console.log('✅ Asis-coder instalado correctamente!');
    console.log('');
    console.log('🎉 Ahora puedes usar:');
    
        console.log('   coder setup      # Configuración inicial');
    console.log('   coder -i         # Modo interactivo');
    console.log('   coder "pregunta" # Consulta directa');
    console.log('');
    
} catch (error) {
    console.error('❌ Error durante la instalación:', error.message);
    console.log('');
    console.log('💡 Puedes intentar la instalación manual:');
    if (isWindows) {
        console.log('   git clone https://github.com/johnolven/asis-coder.git');
        console.log('   cd asis-coder');
        console.log('   # Usar Git Bash o WSL para ejecutar install.sh');
    } else {
        console.log('   git clone https://github.com/johnolven/asis-coder.git');
        console.log('   cd asis-coder');
        console.log('   ./install.sh');
    }
    process.exit(1);
}

function installWindows(packagePath, coderScript) {
    console.log('⚠️  En Windows, recomendamos usar:');
    console.log('   - Git Bash (incluido con Git for Windows)');
    console.log('   - WSL (Windows Subsystem for Linux)');
    console.log('   - PowerShell con bash disponible');
    console.log('');
    console.log('📝 Creando script wrapper para Windows...');
    
    // Crear un script .bat para Windows
    const batScript = path.join(packagePath, 'coder.bat');
    const batContent = `@echo off
REM Asis-coder Windows Wrapper
REM Requiere Git Bash o WSL

where bash >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Error: bash no encontrado
    echo.
    echo 💡 Instala una de estas opciones:
    echo    - Git for Windows ^(incluye Git Bash^)
    echo    - WSL ^(Windows Subsystem for Linux^)
    echo.
    echo Luego usa: coder
    exit /b 1
)

bash "${coderScript.replace(/\\/g, '/')}" %*
`;
    
    fs.writeFileSync(batScript, batContent);
    console.log('✅ Script wrapper creado: coder.bat');
}

function installUnix(packagePath, coderScript) {
    const installScript = path.join(packagePath, 'install.sh');
    const libDir = path.join(packagePath, 'lib');
    
    // Verificar que el script de instalación existe
    if (!fs.existsSync(installScript)) {
        console.error('❌ Error: No se encontró install.sh');
        process.exit(1);
    }
    
    // Crear directorio lib si no existe
    if (!fs.existsSync(libDir)) {
        fs.mkdirSync(libDir, { recursive: true });
    }
    
    // Hacer el script ejecutable
    execSync(`chmod +x "${installScript}"`, { stdio: 'inherit' });
    execSync(`chmod +x "${coderScript}"`, { stdio: 'inherit' });
    
    // Ejecutar el script de instalación
    execSync(`"${installScript}"`, { 
        stdio: 'inherit',
        cwd: packagePath 
    });
} 