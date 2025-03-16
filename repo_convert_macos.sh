#!/bin/bash
# Script para percorrer todos os arquivos de um repositório
# e concatenar seu conteúdo em um único arquivo markdown,
# além de gerar um arquivo com a estrutura de diretórios.

# Configuração para lidar com arquivos e nomes de arquivos grandes
ulimit -n 4096 2>/dev/null  # Aumenta o limite de arquivos abertos se possível

# Configurar IFS para lidar corretamente com nomes de arquivos que contêm espaços
IFS=

echo "Script para converter repositório para arquivo markdown"
echo "------------------------------------------------------"

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
# Verifica se o comando tree está instalado
if command -v tree >/dev/null 2>&1; then
    echo '```' > "$TREE_FILE"
    # Usa tree sem a opção -a para ignorar arquivos ocultos
    tree "$REPO_PATH" >> "$TREE_FILE"
    echo '```' >> "$TREE_FILE"
    echo "Estrutura de diretórios salva em $TREE_FILE"
else
    echo "Comando 'tree' não encontrado. Instalando usando Homebrew..."
    # Verifica se o Homebrew está instalado
    if command -v brew >/dev/null 2>&1; then
        brew install tree
        echo '```' > "$TREE_FILE"
        tree "$REPO_PATH" >> "$TREE_FILE"
        echo '```' >> "$TREE_FILE"
        echo "Estrutura de diretórios salva em $TREE_FILE"
    else
        echo "Homebrew não encontrado. Por favor, instale o Homebrew e o comando 'tree' manualmente."
        echo "Continuando sem gerar o arquivo tree.md..."
    fi
fi

# Função para verificar se o arquivo é binário ou muito grande
is_processable_file() {
    local file="$1"
    
    # # Verificar se é um arquivo binário
    # if ! file -b --mime "$file" | grep -q "^text/"; then
    #     return 1  # Não é texto
    # fi
    
    # Verificar tamanho (pular arquivos maiores que 50MB para evitar problemas de desempenho)
    local size=$(stat -f%z "$file" 2>/dev/null || stat --format="%s" "$file" 2>/dev/null)
    if [ "$size" -gt 52428800 ]; then
        echo "Aviso: Arquivo muito grande (>50MB) ignorado: $file"
        return 1
    fi
    
    return 0  # Arquivo processável
}

# Iniciar a busca recursiva de arquivos (excluindo arquivos ocultos)
export -f is_processable_file  # Necessário para usar a função dentro do find -exec
find "$REPO_PATH" -type f -not -path "*/\.*" | while read -r FILE_PATH; do
    # Verificar se o arquivo é processável (não-binário e não muito grande)
    if is_processable_file "$FILE_PATH"; then
        # Ignorar alguns tipos específicos de arquivos
        if [[ "$FILE_PATH" =~ \.(exe|dll|pdb|obj|bin|dat|zip|rar|7z|jpg|jpeg|png|gif|bmp|ico|mp3|mp4|avi|mov|wmv)$ ]]; then
            continue
        fi
    
        FILE_NAME=$(basename "$FILE_PATH")
        echo "Processando: $FILE_NAME"
        
        # Adicionar cabeçalho com nome do arquivo
        echo "# $FILE_NAME" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Adicionar caminho relativo do arquivo
        REL_PATH="${FILE_PATH#$REPO_PATH}"
        echo "Caminho: $REL_PATH" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Adicionar o conteúdo do arquivo
        echo '```' >> "$OUTPUT_FILE"
        
        # Usar dd para lidar com caracteres especiais e streams binários inesperados
        # e definir um tamanho de bloco grande para melhorar o desempenho
        dd if="$FILE_PATH" bs=1M 2>/dev/null | cat >> "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

echo ""
echo "Processo concluído!"
echo "Todos os arquivos foram combinados em $OUTPUT_FILE"
if [ -f "$TREE_FILE" ]; then
    echo "A estrutura de diretórios foi salva em $TREE_FILE"
fi

# Abrir o diretório raiz onde os arquivos foram gerados
echo "Abrindo o diretório raiz..."
if command -v open >/dev/null 2>&1; then
    # macOS usa o comando 'open' para abrir o diretório no Finder
    open .
elif command -v xdg-open >/dev/null 2>&1; then
    # Linux geralmente usa xdg-open
    xdg-open .
else
    echo "Não foi possível abrir o diretório automaticamente."
fi