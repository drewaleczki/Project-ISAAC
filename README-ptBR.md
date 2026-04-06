# Project ISAAC 🚀

## Visão Geral

**Plataforma de Dados Serverless Ponta-a-Ponta na AWS** desenhada para processar grandes volumes de dados com uma arquitetura focada em FinOps, utilizando S3, Glue, Athena, dbt, Terraform e Step Functions.

Arquitetura projetada para:
- minimizar custos de infraestrutura
- garantir a qualidade dos dados
- escalar livremente
- operar em um modelo 100% serverless

---

Enquanto aguardava a chegada do meu filho, Isaac, decidi batizar meu novo projeto de arquitetura de dados em sua homenagem. O **Project ISAAC** não é apenas um pipeline, mas uma exploração prática de arquiteturas em nuvem escaláveis e princípios modernos de Engenharia de Dados. A escolha do nome reflete exatidão e a grandiosidade de impacto esperado — ecoando tanto os princípios do físico Isaac Newton quanto minha nova jornada na paternidade.

## 🎯 Objetivo do Projeto

Este projeto foi **desenhado para simular decisões reais de arquitetura em produção**. O foco vai muito além de "mover tabelas de um lado para o outro"; engloba a adoção de práticas sólidas do mercado para minimizar o esforço operacional por meio de automação extensiva.

Nesta plataforma, consolidamos:
- **Integração Cloud-Nativa:** Uso profundo do ecossistema AWS gerido de forma segura via IAM.
- **Processamento de Big Data:** Jobs robustos e distribuídos utilizando PySpark.
- **Confiabilidade:** Validação na esteira de dados com regras de Data Quality (Data Contracts).
- **Gestão de Infraestrutura:** Automação com IaC, CI/CD, DevOps e FinOps.

## 💡 O que este projeto demonstra

- Engenharia de Dados Ponta-a-Ponta (End-to-End)
- Arquitetura AWS Serverless
- IaC (Infrastructure as Code)
- Otimização Analítica e FinOps
- Data Quality utilizando dbt
- Processamento Distribuído com PySpark
- Orquestração Orientada a Eventos (Event-driven)
- CI/CD aplicado a Plataformas de Dados

## 🛠️ Stack Tecnológico

- **Cloud Provider:** Amazon Web Services (AWS)
- **Data Lake (Armazenamento):** Amazon S3 (Camadas Bronze, Silver, e Gold)
- **Processamento Big Data:** PySpark via AWS Glue
- **Analytics Engineering & Qualidade:** dbt (Data Build Tool)
- **Serving Layer:** Amazon Athena
- **Orquestração:** AWS Step Functions + EventBridge Scheduler
- **Infraestrutura como Código (IaC):** Terraform
- **CI/CD:** GitHub Actions 

## 🗺️ Diagrama de Arquitetura

![Diagrama da Arquitetura](docs/images/architecture_diagram.png)

**Pipeline:**
AWS Lambda → S3 Bronze → AWS Glue → S3 Silver → Amazon Athena + dbt → S3 Gold → AWS Step Functions

## 🏛️ Decisões Arquiteturais

Esta seção aborda as decisões técnicas que diferenciam este projeto de um laboratório simples, elevando-o a um padrão de produção realista.

### dbt vs. Gold Refresher Lambda: Duas Ferramentas, Duas Responsabilidades

Uma das abordagens centrais da camada de negócio (Gold Layer) é o uso de duas pontas distintas para trabalhar a arquitetura:

| Abordagem | Ferramenta | Gatilho | Objetivo |
|---|---|---|---|
| **Deploy** | `dbt-core` (GitHub Actions) | Push na branch `master` | Valida a lógica SQL, aplica as restrições de Qualidade (`not_null`, `unique`) e inicializa as tabelas durante a automação do CI/CD. |
| **Materialização Diária** | Lambda Gold Refresher (Step Functions) | Schedule cron via EventBridge | Repete diariamente as queries CTAS via banco Athena utilizando `boto3` para garantir dados analíticos atualizados e frescos. |

**Por que não rodar o dbt no schedule diário?** Manter um container de `dbt-core` no ar apenas para as rodadas diárias exigiria um servidor dedicado rodando 24x7 (como uma instância EC2 constante), com custos de ~$15 a $30 mensais por ambiente. Esse teto quebra o nosso princípio vital de FinOps (Pay-per-use puro). A Lambda contorna isso custando microscópicos centavos de dólar enquanto delega a carga de execução nativamente para a engine do AWS Athena.

### Airflow vs. AWS Step Functions

Originalmente o projeto mapeava a utlização do Apache Airflow. Contudo, após avaliar o balanceamento de recursos, o **AWS Step Functions** tornou-se a escolha ideal:

| Requisito | Apache Airflow (MWAA/EC2) | AWS Step Functions |
|---|---|---|
| Infraestrutura | Servidores sempre rodando | 100% Serverless |
| Custo Operacional | Elevado (~$15-30/mês devido a ociosidade) | Baseado em transições de execução (praticamente gratuito neste cenário) |
| Visual DAG | Interface Web do Airflow | Mapa visual integrado no próprio Console da AWS |
| Resiliência a Falhas | Tratamento em DAG Python Customizado | Integração direta de alertas via AWS SNS Error Catch blocks |

A orquestração nativa pelo Step Functions eliminou totalmente a carga operacional de manter servidores funcionando apenas para agendamento e retry de tarefas.

## 📍 Roteiro de Execução

- **Etapa 1: Base em Terraform (Concluído) ✔️**
  - Implementação inicial de Infraestrutura como Código separando logs seguros locais.
- **Etapa 2: Aterramento Storage Data Lake (Concluído) ✔️**
  - Defesa virtual criando lagos lógicos S3 e dividindo-os nas zonas Raw, Trusted, e Refined.
- **Etapa 3: Ingestão de Dados por API (Concluído) ✔️**
  - Cloud-Native puramente gerida via Lambda para executar transferências pontuais autônomas depositando dados em formato original.
- **Etapa 4: Motor de Big Data - PySpark e Glue (Concluído) ✔️**
  - Construção de instâncias isoladas de Spark que transformam CSV bruto em blocos lógicos Parquet criptografados paralelamente no Data Lake.
- **Etapa 5: Analytics & Orquestração (Concluído) ✔️**
  - Arquitetura orquestrada usando Step Functions integrando CTAS nativos isolando e tratando erros ponta a ponta na esteira Event-Driven!

## 📸 Vitrine da Arquitetura

Demonstração do motor operacional em nuvem funcionando:

### 1. Visualização e Fluxo do DAG (Step Functions)
*Execução event-driven visualizando status de transição interligados.*
![AWS Step Functions DAG Success](docs/images/step_functions_dag_success.png)

### 2. Ingestão Cloud-Native via Lambda
*Logs do serviço nativo Amazon rastreando as injeçõoes sem instâncias provisionadas no ecossistema Raw.*
![AWS Lambda Logs](docs/images/lambda_logs.png)

### 3. Camada Raw Bronze (S3 Landing Zone)
*Demonstração do pouso desfragmentado e limpo salvo com segurança nos painéis de storage Amazon.*
![S3 Data Lake landing](docs/images/s3_bronze_landing.png)

### 4. Continuous Deployment CI/CD Pipeline
*Integração perfeita executada via repositório. Código em produção acionando automaticamente mudanças Cloud.*
![GitHub Actions Pipeline](docs/images/github_actions_pipeline.png)

### 5. Big Data Processing Scale PySpark
*Workers de processamento dividindo nós num formato massivo nas planilhas do Glue Spark execution framework.*
![AWS Glue Execution](docs/images/glue_pyspark_execution.png)

### 6. Optimização de Camada (Parquet/Silver Encryption)
*Visual de pastas compactadas operando conversão estrita do Lake formation format formatation para Athena.*
![S3 Silver Storage](docs/images/s3_silver_parquet.png)

### 7. Catálogo Relacional Automático
*Dynamo Crawler acoplando as origens no Data Catalog liberando consulta visual na rede relacional em SQL clássico.*
![AWS Glue Data Catalog](docs/images/glue_data_catalog.png)


## 💰 FinOps: Projeção Analítica Comercial

Trabalhar focado em otimização financeira ("FinOps") torna o produto absurdamente barato. Se transpusermos esta exata infra-estrutura escalável Serverless desenvolvida aqui para processar pesados **500 Gigabytes diários** vindos do mercado, o balanço técnico projetado ficaria desta forma:

| Camada | Produto Cloud | Métrica Operacional AWS | Estimativa Mensal Extrapolada (EUA $) |
|---|---|---|---|
| **Storage Data Lake** | Amazon S3 | Retenção constante massiva em bucket Standard (500GB) | ~$11.50 |
| **Ingestão via API** | AWS Lambda | Execução diária da rotina c/ spans tolerando 300 Segundos. | ~$0.10 |
| **Processamento Analítico** | AWS Glue | Nós de computação (DPUs) girando limite máximo ~30 horas uso mensal | ~$132.00 |
| **Painel Business Query** | Amazon Athena | Trino Scanner Engine cobrando sobre a varredura .parquet (~3TB Processado) | ~$15.00 |
| **Custo de Orquestração** | Step Functions | Tracking log cobrado baseando-se por estado transicionado (300 States Base) | ~$0.00 |
| **Deploy Pipeline CI/CD** | Actions Runner | Ubuntu runtime acoplado na conta Github Limits rodando ações build base IaC | ~$0.00 |
| **Cálculo da Operação Base Mensal Mapeada** | | | **~$158.60 / Mês** |

> **Vantagem Competitiva Comercial:** A maior parte do mercado adota estruturas em máquinas sempre ligadas usando tradicionais Data Warehouses em containers alugados ininterruptamente (Ex: AirFlow instanciado atrelado na base com RedShift faturando tempo de espera e o motor Apache Spark Node Master fixado parado pronto para rodadas). Manter tudo ligado ocioso 24 horas pode gerar tetos passivos girando na casa dos **$800 a $1,500 dólares ao mês!** Mesmo se rodarmos zero dados. Como "Projeto ISAAC" opera num pilar de Event-Driven Functions, seu *idle baseline* financeiro vai a $0, faturando rigorosamente apenas em cima da milisegundagem exigida de gigabytes inseridos, escalonando proporcionalmente sem sustos.

## ⚠️ Troubleshooting Mapeado 

Ao desenvolver este framework na prática, alguns bloqueios e bugs silenciosos padrão da Infraestrutura Amazon surgiram e foram resolvidos:

### 1. Desconexão do Spark (`AnalysisException: Database not found`)
Se executarmos o comando simples `saveAsTable()` internamente num Python Script disparado por um servidor dinâmico do AWS Glue, o processador sobe o serviço isolando a leitura em um Metastore virtual próprio, esquecendo totalmente da real base oficial formatada pelo Terraform (`isaac_silver`), causando corrupção imediata da querie PySpark e colapso de job!
**Solução Aplicada:** O arquivo gerador de infraestrutura IaC (Terraform) precisa acoplar explicitamente o acionador para forçar o Spark Core a usar o serviço de Catálogo original Amazon. Resolvemos definindo nos argumentos base do recurso `aws_glue_job`:  `default_arguments = { "--enable-glue-datacatalog" = "true" }`.

### 2. Tratativa de Permissões Crônicas no AWS IAM (Athena/Lambda DDL Execution via StepFunctions)
Quando orquestramos o descarte e reconstrução de visões finais de tabelas analíticas ("CTAS e DROP/Update Views") usando Step Functions para guiar o motor remoto relacional do Athena via framework Boto-3, a plataforma sofre engarrafamentos massivos pois o modelo padrão básico IAM (Read e Write do bucket) não tem alçada superior para reestruturar DataCatalogs nas entranhas da máquina. Apareceram logs destrutivos nos processos como "Unable to Verify Output Location" e "Access Denied Amazon Excepetion: Glue:DeleteTable". 
**Solução Aplicada:** Via base de infraestrutura IaC, nós forçamos nos policies virtuais atrelados permissões explícitas liberando engates aos DDL Rules internos da AWS Glue (`glue:DeleteTable`, `glue:UpdateTable`, `glue:CreateTable`) nos recursos Cloud permitindo o expurgo livre de metadados antigos, além de abrir atestadamente star rules na pasta Amazon S3 Output Log Tracker permitindo que o sistema despeje os multi-uploads analíticos Trino gerados pós querying base! E por fim, cravados sufixo estrito `.sync` integrando limpo event rule tracker.

---

> *"If I have seen further it is by standing on the shoulders of Giants." — Isaac Newton*

## 🤝 Feedbacks e Colaborações
Visões e trocas de conhecimento corporativo são fundamentais para crescermos neste ecossitema gigante Cloud Native!
Sinta-se inteiramente livre pra opinar, discutir abordagens de projeto nas Issues ou contribuir no espaço aberto deste repositório matriz!
