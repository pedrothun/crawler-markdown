#!/bin/bash
# Script para percorrer todos os arquivos de um repositório no Windows usando GitBash
# e concatenar seu conteúdo em um único arquivo markdown,
# além de gerar um arquivo com a estrutura de diretórios.

echo "Script para converter repositório para arquivo markdown (GitBash no Windows)"
echo "----------------------------------------------------------------------"

# Definir diretório raiz como a pasta atual onde o script está sendo executado
REPO_PATH="$(pwd)"
echo "Usando diretório atual como repositório: $REPO_PATH"

# Definir nome do arquivo de saída
OUTPUT_FILE="repositorio_completo.md"
TREE_FILE="tree.md"

# Remover arquivos existentes (se houver)
[ -f "$OUTPUT_FILE" ] && rm "$OUTPUT_FILE"
[ -f "$TREE_FILE" ] && rm "$TREE_FILE"

echo "Processando arquivos..."

# Gerar o arquivo tree.md com a estrutura do repositório
# Em GitBash no Windows, podemos usar o comando tree do Windows
if command -v tree.com >/dev/null 2>&1; then
    # Comando tree do Windows está acessível via tree.com no GitBash
    echo '```' > "$TREE_FILE"
    cmd.exe //c "tree /F /A" >> "$TREE_FILE"
    echo '```' >> "$TREE_FILE"
    echo "Estrutura de diretórios salva em $TREE_FILE"
elif command -v tree >/dev/null 2>&1; then
    # Tree do Unix está disponível
    echo '```' > "$TREE_FILE"
    tree "$REPO_PATH" >> "$TREE_FILE"
    echo '```' >> "$TREE_FILE"
    echo "Estrutura de diretórios salva em $TREE_FILE"
else
    echo "Comando tree não encontrado. A estrutura de diretórios não será criada."
fi

# Criar arquivo de saída com cabeçalho
echo "# Repositório completo" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Data de geração: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Função para verificar se o arquivo é texto ou binário
is_text_file() {
    local file="$1"
    
    # Lista de extensões de arquivos binários para ignorar
    if [[ "$file" =~ \.(exe|dll|pdb|obj|bin|dat|zip|rar|7z|jpg|jpeg|png|gif|bmp|ico|mp3|mp4|avi|mov|wmv)$ ]]; then
        return 1
    fi
    
    # Lista de extensões sempre tratadas como texto
    if [[ "$file" =~ \.(txt|md|py|js|html|css|java|c|cpp|h|cs|php|rb|pl|sh|bat|ps1|json|xml|yml|yaml|toml|ini|cfg|config|ipynb|sql|r)$ ]]; then
        return 0
    fi
    
    # Verificar o tamanho do arquivo (ignorar arquivos > 50MB)
    local size=$(stat -c %s "$file" 2>/dev/null || stat --format="%s" "$file" 2>/dev/null || ls -la "$file" | awk '{print $5}')
    if [ -n "$size" ] && [ "$size" -gt 52428800 ]; then
        echo "Aviso: Arquivo muito grande (>50MB) ignorado: $file"
        return 1
    fi
    
    # Verificar se é um arquivo de texto utilizando o comando file
    if command -v file >/dev/null 2>&1; then
        file -b --mime "$file" | grep -q "^text/" && return 0
    fi
    
    # Se o comando file não estiver disponível, usar um método alternativo
    # Verificar pelos primeiros 1024 bytes por caracteres nulos
    if head -c 1024 "$file" 2>/dev/null | grep -q "$(printf '\0')"; then
        return 1  # Contém bytes nulos = binário
    fi
    
    return 0  # Provavelmente texto
}

# Função para processar um arquivo
process_file() {
    local FILE_PATH="$1"
    local FILE_NAME=$(basename "$FILE_PATH")
    
    echo "Processando: $FILE_NAME"
    
    # Adicionar cabeçalho com nome do arquivo
    echo "# $FILE_NAME" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Adicionar caminho relativo do arquivo
    # Em GitBash no Windows, os caminhos podem ter mistura de / e \
    REL_PATH="${FILE_PATH#$REPO_PATH}"
    REL_PATH="${REL_PATH#/}"
    echo "Caminho: $REL_PATH" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Adicionar o conteúdo do arquivo
    echo '```' >> "$OUTPUT_FILE"
    
    # Usar cat para adicionar o conteúdo, redirecionando erros
    cat "$FILE_PATH" 2>/dev/null >> "$OUTPUT_FILE" || echo "[Erro ao ler o arquivo]" >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Iniciar a busca recursiva de arquivos (excluindo arquivos ocultos)
echo "Buscando arquivos para processar..."

# O find no GitBash do Windows pode ter algumas peculiaridades
# Vamos usar um loop para processar cada arquivo
while IFS= read -r FILE_PATH; do
    # Verificar se o arquivo é texto
    if is_text_file "$FILE_PATH"; then
        process_file "$FILE_PATH"
    fi
done < <(find "$REPO_PATH" -type f -not -path "*/\.*" 2>/dev/null)

echo ""
echo "Processo concluído!"
echo "Todos os arquivos foram combinados em $OUTPUT_FILE"
if [ -f "$TREE_FILE" ]; then
    echo "A estrutura de diretórios foi salva em $TREE_FILE"
fi

# Abrir o diretório raiz onde os arquivos foram gerados (usando comando do Windows)
echo "Abrindo o diretório raiz..."
explorer.exe "."
