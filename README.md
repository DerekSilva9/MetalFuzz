# MetalFuzz

**MetalFuzz** é uma ferramenta de reconhecimento e fuzzing para pentesters e profissionais de segurança da informação. Ela automatiza o processo de coleta de subdomínios, identificação de URLs vulneráveis e execução de testes de fuzzing em sites, utilizando diversas ferramentas essenciais do ecossistema de segurança.

## Funcionalidades

- **Subdomain Enumeration**: Coleta subdomínios utilizando ferramentas como `Subfinder`, `Findomain` e `Katana`.
- **Teste de Atividade de Domínios**: Verifica quais subdomínios estão ativos utilizando `HTTPX`.
- **Fuzzing de URLs**: Identifica parâmetros vulneráveis nas URLs e realiza fuzzing com `QSReplace` e `Nuclei`.
- **Detecção de Vulnerabilidades**: Realiza testes de segurança utilizando templates do `Nuclei`.

## Dependências

Antes de executar o **MetalFuzz**, você precisa garantir que as seguintes ferramentas estejam instaladas em seu sistema:

### Instalação das dependências:

Você pode instalar essas ferramentas no seu sistema utilizando `apt`, `brew`, `go` ou de acordo com o método recomendado para cada uma. Aqui estão os links de instalação para cada ferramenta:


- **[Subfinder](https://github.com/subfinder/subfinder)**: Ferramenta para busca de subdomínios.
- **[Findomain](https://github.com/Findomain/Findomain)**: Outra ferramenta para busca de subdomínios.
- **[Katana](https://github.com/projectdiscovery/katana)**: Ferramenta para busca de URLs.
- **[HTTPX](https://github.com/projectdiscovery/httpx)**: Ferramenta para verificação de domínios ativos.
- **[QSReplace](https://github.com/tomnomnom/qsreplace)**: Substitui parâmetros de URL para fuzzing.
- **[Nuclei](https://github.com/projectdiscovery/nuclei)**: Ferramenta para execução de templates de fuzzing e detecção de vulnerabilidades.
- **[Anew](https://github.com/tomnomnom/anew)**: Ferramenta para atualizar e combinar resultados de diferentes fontes.

## Logs e Resultados

Os resultados serão armazenados na pasta criada automaticamente, com o nome resultados_<dominio>, e os logs de erro são salvos em um arquivo chamado erro.log.

Exemplo de estrutura de diretórios de resultados:

```
resultados_example.com/
│
├── subdomains.txt        # Subdomínios encontrados
├── ativos.txt            # Subdomínios ativos
├── urls.txt              # URLs encontradas
├── urls_parametros.txt   # URLs com parâmetros
├── urls_fuzz.txt         # URLs com parâmetros substituídos por FUZZ
├── refletidos.txt        # URLs refletidas no HTML
├── nuclei_fuzzing.txt    # Resultados de fuzzing com Nuclei
└── nuclei_results_general.txt  # Resultados gerais de vulnerabilidades

```