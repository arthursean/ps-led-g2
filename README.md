# 🚖 Nova York Taxi Data - Processo Seletivo LED G2 (CIn-UFPE)

Repositório do projeto destinado ao processo seletivo da **Liga de Engenharia de Dados do CIn-UFPE**. Este projeto realiza a ingestão, tratamento e modelagem dimensional de dados de viagens de táxi da cidade de Nova York (Janeiro de 2024), utilizando o **DuckDB**.

---

## 📂 Estrutura dos Arquivos

* `yellow_tripdata_2024-01.parquet`: Base de dados bruta contendo as viagens de táxi.
* `taxi_zone_lookup.csv`: Tabela auxiliar com os nomes das zonas de embarque e desembarque.
* `modelo_dimensional.sql`: Script responsável pela criação da estrutura do banco de dados (Tabelas Fato, Dimensões e Sequências).
* `tratamento.sql`: Script responsável pela ingestão dos arquivos bruto, limpeza, criação de views de transformação e inserção dos dados limpos no modelo dimensional.
* `Consultas Perfilamento.sql`: Consultas de análise exploratória e validação utilizando funções nativas do DuckDB.

---

## 🚀 Como reconstruir o banco de dados do zero

Este banco de dados foi projetado para ser 100% reproduzível utilizando apenas os arquivos deste repositório e o **DuckDB**. Siga o passo a passo abaixo para rodar o projeto localmente:

### Passo 1: Instale o DuckDB
Caso não possua o DuckDB instalado em sua máquina:
1. Acesse a [página de instalação do DuckDB](https://duckdb.org/docs/installation/).
2. Faça o download do executável correspondente ao seu sistema operacional.
3. Extraia o executável (`duckdb.exe` no Windows ou `duckdb` no Linux/Mac).

### Passo 2: Prepare o ambiente
1. Clone este repositório para a sua máquina local:
   ```bash
   git clone <https://github.com/arthursean/ps-led-g2>
   ```
2. Abra o seu terminal de preferência (Prompt de Comando, PowerShell ou Terminal do Linux/Mac) e navegue até a pasta do projeto:
   ```bash
   cd caminho/para/a/pasta/ps-led-g2
   ```

### Passo 3: Criando e populando o banco no DuckDB
Dentro da pasta do projeto, inicie o DuckDB apontando para um novo arquivo de banco de dados (isso garantirá que os dados sejam salvos localmente):

```bash
duckdb banco_taxi_ny.db
```
*(Nota: Se o DuckDB não estiver nas suas variáveis de ambiente, coloque o executável baixado no Passo 1 dentro da pasta do projeto e abra-o).*

Agora, dentro do terminal interativo do DuckDB (onde o prompt `D` aparece), execute os scripts SQL estritamente na seguinte ordem utilizando o comando `.read`:

```sql
-- 1. Cria a estrutura do Banco de Dados (Tabelas e constraints)
.read 'modelo_dimensional.sql'

-- 2. Realiza a leitura do Parquet/CSV, limpa os dados e popula o modelo
.read 'tratamento.sql'

-- 3. (Opcional) Execute as consultas de perfilamento para verificar os resultados
.read 'Consultas Perfilamento.sql'
```

**Pronto!** O banco de dados foi construído do zero, estruturado em um modelo dimensional (Star Schema) e está pronto para consultas. Para sair do DuckDB, basta digitar `.exit`.
