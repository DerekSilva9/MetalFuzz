#!/bin/bash

# Função para exibir o banner
show_banner() {
    # Define a cor do banner (opcional)
    echo -e "\033[0;31m"  # Vermelho
    figlet -f slant "Metal-FuZz" | tee /dev/null
    echo -e "\033[0m"     # Resetar cor
    echo -e "DerekSilva"
    echo -e "v1"
    echo -e "===========================\n"
}

# Exibe o banner ao iniciar o script
show_banner

# Verifica dependências
check_dependency() {
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "A ferramenta $1 não está instalada. Instale-a antes de executar o script."; exit 1; }
}

# Checando ferramentas essenciais
check_dependency "subfinder"
check_dependency "findomain"
check_dependency "katana"
check_dependency "httpx"
check_dependency "qsreplace"
check_dependency "nuclei"
check_dependency "anew"

# Verifica se o domínio foi fornecido
if [ "$#" -lt 1 ]; then
    echo "Uso: $0 <dominio> [-tb <threads_subfinder>] [-tk <threads_katana>] [-th <threads_httpx>]"
    exit 1
fi

ALVO=$1
DOMINIO=$(echo $ALVO | sed -E 's/https?:\/\///' | sed 's/\/.*//') # Extrai o domínio do URL
PASTA_RESULTADOS="resultados_$(echo $DOMINIO | tr -cd '[:alnum:]-_')"

# Lê os parâmetros de threads
THREADS_SUBFINDER=1
THREADS_KATANA=1
THREADS_HTTPX=1

# Analisa opções de threads
shift
while getopts "tb:tK:tk:th:" opt; do
    case $opt in
        tb) THREADS_SUBFINDER="$OPTARG";;
        tk) THREADS_KATANA="$OPTARG";;
        th) THREADS_HTTPX="$OPTARG";;
        \?) echo "Opção inválida: -$OPTARG" >&2; exit 1;;
    esac
done

# Cria uma pasta para armazenar os resultados
mkdir -p $PASTA_RESULTADOS
LOGFILE="$PASTA_RESULTADOS/erro.log"
exec 2>>"$LOGFILE"
echo "Resultados serão salvos na pasta: $PASTA_RESULTADOS"

# Etapa 1: Subfinder
echo -e "\n=====================\n[+] Executando Subfinder...\n====================="
if ! subfinder -d $DOMINIO -silent -t $THREADS_SUBFINDER | tee $PASTA_RESULTADOS/subdomains.txt; then
    echo "[!] Erro ao executar Subfinder."
    exit 1
fi

# Etapa 2: Findomain
echo -e "\n=====================\n[+] Executando Findomain...\n====================="
findomain -t $DOMINIO -q | anew $PASTA_RESULTADOS/subdomains.txt

# Etapa 3: Katana
echo -e "\n=====================\n[+] Executando Katana...\n====================="
katana -u $ALVO -silent -c $THREADS_KATANA -o $PASTA_RESULTADOS/urls.txt

# Etapa 4: HTTPX
echo -e "\n=====================\n[+] Procurando por domínios ativos com HTTPX...\n====================="
if ! httpx -silent -l $PASTA_RESULTADOS/subdomains.txt -o $PASTA_RESULTADOS/ativos.txt -threads $THREADS_HTTPX; then
    echo "[!] Erro ao executar HTTPX."
    exit 1
fi

if [ ! -s $PASTA_RESULTADOS/ativos.txt ]; then
    echo "[!] Nenhum domínio ativo encontrado."
    exit 1
fi

# Etapa 5: Buscar parâmetros com grep e QSReplace
echo -e "\n=====================\n[+] Buscando URLs com parâmetros...\n====================="
grep '?' $PASTA_RESULTADOS/urls.txt | tee $PASTA_RESULTADOS/urls_parametros.txt

if [ -s $PASTA_RESULTADOS/urls_parametros.txt ]; then
    echo -e "\n[+] Substituindo parâmetros com 'FUZZ'..."
    cat $PASTA_RESULTADOS/urls_parametros.txt | qsreplace 'FUZZ' | tee $PASTA_RESULTADOS/urls_fuzz.txt

    echo -e "\n[+] Buscando URLs refletidos no HTML..."
    cat $PASTA_RESULTADOS/urls_fuzz.txt | httpx -match-string 'FUZZ' -silent -t 200 -o $PASTA_RESULTADOS/refletidos.txt
else
    echo "[!] Nenhuma URL com parâmetros encontrada."
fi

# Etapa 6: Atualizar templates do Nuclei
echo -e "\n=====================\n[+] Atualizando templates do Nuclei...\n====================="
if ! nuclei -update-templates; then
    echo "[!] Erro ao atualizar templates do Nuclei."
    exit 1
fi

# Etapa 7: Testes de vulnerabilidades com Nuclei (Fuzzing)
echo -e "\n=====================\n[+] Executando Nuclei para fuzzing...\n====================="
if ! cat $PASTA_RESULTADOS/refletidos.txt | nuclei -t fuzzing-templates --fuzz -c 150 -o $PASTA_RESULTADOS/nuclei_fuzzing.txt; then
    echo "[!] Erro ao executar Nuclei para fuzzing."
    exit 1
fi


# Etapa 8: Scans gerais com Nuclei
echo -e "\n=====================\n[+] Executando Nuclei para detecção geral...\n====================="
if ! nuclei -l $PASTA_RESULTADOS/ativos.txt -o $PASTA_RESULTADOS/nuclei_results_general.txt; then
    echo "[!] Erro ao executar Nuclei para detecção geral."
    exit 1
fi

echo -e "\n[+] Recon concluído! Resultados salvos em $PASTA_RESULTADOS."
