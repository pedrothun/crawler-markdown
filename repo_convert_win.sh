@echo off
setlocal enabledelayedexpansion

echo Script para converter repositório para arquivo markdown (Windows)
echo --------------------------------------------------------------

:: Definir diretório raiz como a pasta atual onde o script está sendo executado
set "REPO_PATH=%CD%"
echo Usando diretório atual como repositório: %REPO_PATH%

:: Definir nome do arquivo de saída
set "OUTPUT_FILE=repositorio_completo.md"
set "TREE_FILE=tree.md"

:: Remover arquivos existentes (se houver)
if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"
if exist "%TREE_FILE%" del "%TREE_FILE%"

echo Processando arquivos...

:: Verificar se o comando tree está disponível (já vem com Windows)
echo ```> "%TREE_FILE%"
tree /F /A "%REPO_PATH%" >> "%TREE_FILE%"
echo ```>> "%TREE_FILE%"
echo Estrutura de diretórios salva em %TREE_FILE%

:: Criar arquivo de saída com cabeçalho
echo # Repositório completo > "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo Data de geração: %date% %time% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

:: Usar PowerShell para processar os arquivos de forma mais eficiente
powershell -ExecutionPolicy Bypass -Command "& {
    # Obter caminho do repositório
    $repoPath = '%REPO_PATH%'
    $outputFile = '%OUTPUT_FILE%'
    
    # Extensões de arquivos binários para ignorar
    $binaryExtensions = @('.exe', '.dll', '.pdb', '.obj', '.bin', '.dat', 
                          '.zip', '.rar', '.7z', '.jpg', '.jpeg', '.png', 
                          '.gif', '.bmp', '.ico', '.mp3', '.mp4', '.avi', 
                          '.mov', '.wmv')
    
    # Função para verificar se um arquivo é texto ou binário
    function Test-IsTextFile {
        param ([string]$filePath)
        
        # Verificar a extensão primeiro
        $extension = [System.IO.Path]::GetExtension($filePath)
        if ($binaryExtensions -contains $extension) {
            return $false
        }
        
        # Verificar o tamanho do arquivo (ignorar arquivos > 50MB)
        $fileInfo = Get-Item $filePath
        if ($fileInfo.Length -gt 52428800) {
            Write-Host ('Aviso: Arquivo muito grande (>50MB) ignorado: ' + $filePath)
            return $false
        }
        
        # Ler os primeiros 8KB do arquivo para verificar se é binário
        try {
            $byteArray = Get-Content -Path $filePath -Encoding Byte -TotalCount 8KB -ErrorAction Stop
            $detectBinary = $false
            $nullCount = 0
            
            # Contar caracteres nulos
            foreach ($byte in $byteArray) {
                if ($byte -eq 0) {
                    $nullCount++
                    if ($nullCount -gt 1) {
                        $detectBinary = $true
                        break
                    }
                }
            }
            
            # Se mais de 10% são caracteres não imprimíveis, considerar binário
            $nonPrintable = 0
            foreach ($byte in $byteArray) {
                if (($byte -lt 32 -and $byte -ne 9 -and $byte -ne 10 -and $byte -ne 13) -or $byte -gt 127) {
                    $nonPrintable++
                }
            }
            
            if ($byteArray.Length -gt 0 -and ($nonPrintable / $byteArray.Length) -gt 0.1) {
                $detectBinary = $true
            }
            
            return -not $detectBinary
        }
        catch {
            Write-Host ('Erro ao ler o arquivo: ' + $filePath)
            return $false
        }
    }
    
    # Sempre processar certos tipos de arquivos de texto
    function Is-AlwaysProcessFile {
        param ([string]$filePath)
        
        $textExtensions = @('.txt', '.md', '.py', '.js', '.html', '.css', '.java', '.c', '.cpp', '.h', 
                           '.cs', '.php', '.rb', '.pl', '.sh', '.bat', '.ps1', '.json', '.xml', '.yml',
                           '.yaml', '.toml', '.ini', '.cfg', '.config', '.ipynb', '.sql', '.r')
        
        $extension = [System.IO.Path]::GetExtension($filePath)
        return $textExtensions -contains $extension
    }
    
    # Recebe todos os arquivos, excluindo diretórios ocultos
    $files = Get-ChildItem -Path $repoPath -File -Recurse | 
             Where-Object { $_.FullName -notmatch '\\\\\.[\w\d]+\\\\' }
    
    # Processa cada arquivo
    foreach ($file in $files) {
        $isTextFile = (Is-AlwaysProcessFile $file.FullName) -or (Test-IsTextFile $file.FullName)
        
        if ($isTextFile) {
            $fileName = $file.Name
            Write-Host ('Processando: ' + $fileName)
            
            # Calcular caminho relativo
            $relPath = $file.FullName.Substring($repoPath.Length)
            if ($relPath.StartsWith('\')) {
                $relPath = $relPath.Substring(1)
            }
            
            # Adicionar ao arquivo de saída
            Add-Content -Path $outputFile -Value ('# ' + $fileName)
            Add-Content -Path $outputFile -Value ''
            Add-Content -Path $outputFile -Value ('Caminho: ' + $relPath)
            Add-Content -Path $outputFile -Value ''
            Add-Content -Path $outputFile -Value '```'
            
            # Ler o conteúdo do arquivo e adicioná-lo
            try {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
                Add-Content -Path $outputFile -Value $content -NoNewLine
            }
            catch {
                Add-Content -Path $outputFile -Value '[Erro ao ler o arquivo]'
            }
            
            Add-Content -Path $outputFile -Value ''
            Add-Content -Path $outputFile -Value '```'
            Add-Content -Path $outputFile -Value ''
            Add-Content -Path $outputFile -Value ''
        }
    }
}"

echo.
echo Processo concluído!
echo Todos os arquivos foram combinados em %OUTPUT_FILE%
echo A estrutura de diretórios foi salva em %TREE_FILE%

:: Abrir o diretório raiz onde os arquivos foram gerados
echo Abrindo o diretório raiz...
explorer .

echo.
pause
