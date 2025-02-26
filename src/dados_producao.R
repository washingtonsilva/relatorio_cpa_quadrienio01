

# Carrega os pacotes necessários
library(tidyverse)
library(here)


# Definindo os caminhos de entrada e saída usando o pacote here
arquivo_entrada <- here("dados/brutos", "producoes_discentes.csv")
arquivo_saida_csv <- here("dados/limpos", "producoes_concluintes.csv")
arquivo_saida_rds <- here("dados/limpos", "producoes_concluintes.rds")

# Leitura do arquivo CSV
dados <- read_csv(arquivo_entrada, skip = 2)

# 1. Alterando os nomes das variáveis
dados_renomeados <- dados %>%
  rename(
    id = `NOME CONCLUINTE`,
    turma = `TURMA`,
    tipo = `TIPO DE PRODUÇÃO`,
    subtipo = `SUBTIPO`,
    natureza = `NATUREZA`,
    titulo = `TÍTULO`,
    papel = `Papel`
  )

# 2. Tornando a estrutura de dados tidy
# Observei que os dados têm uma estrutura onde linhas em branco (com id vazio)
# são continuações da linha anterior
dados_tidy <- dados_renomeados %>%
  # Preenchendo os valores vazios de id, turma com o valor da linha anterior
  fill(id, turma) %>%
  # Removendo linhas completamente vazias
  filter(!(
    is.na(tipo) &
      is.na(subtipo) &
      is.na(natureza) & is.na(titulo) & is.na(papel)
  )) %>%
  # Removendo espaços em branco extras
  mutate(across(everything(), ~ str_trim(as.character(.)))) %>%
  # Lidando com valores vazios
  mutate(across(everything(), ~ na_if(., "")))

# 3. Alterando os valores da variável turma
dados_processados <- dados_tidy %>%
  mutate(turma = case_when(turma == "2021.1" ~ "2021", turma == "2022.1" ~ "2022", TRUE ~ turma))

# 4. Alterando os valores da variável tipo
dados_processados <- dados_processados %>%
  mutate(tipo = case_when(
    str_detect(toupper(tipo), "BIBLIOGR[ÁA]FICA") ~ "Bibliográfica",
    str_detect(toupper(tipo), "T[ÉE]CNICA") ~ "Técnica",
    TRUE ~ tipo
  ))

# 5. Alterando os valores da variável subtipo
dados_processados <- dados_processados %>%
  mutate(
    subtipo = case_when(
      str_detect(toupper(subtipo), "SERVI[ÇC]OS T[ÉE]CNICOS") ~ "Trabalhos Técnicos",
      str_detect(toupper(subtipo), "APRESENTA[ÇC][ÃA]O DE TRABALHO") ~ "Trabalhos Técnicos",
      str_detect(toupper(subtipo), "ARTIGO EM PERI[ÓO]DICO") ~ "Artigo em Periódico",
      str_detect(toupper(subtipo), "TRABALHO EM ANAIS") ~ "Trabalho em Anais",
      str_detect(toupper(subtipo), "DESENVOLVIMENTO DE T[ÉE]CNICA") ~ "Desenvolvimento de Técnica",
      str_detect(toupper(subtipo), "CURSO DE CURTA DURA[ÇC][ÃA]O") ~ "Curso de Curta Duração",
      str_detect(
        toupper(subtipo),
        "DESENVOLVIMENTO DE MATERIAL DID[ÁA]TICO E INSTRUCIONAL"
      ) ~
        "Desenvolvimento de Material Didático e Instrucional",
      str_detect(toupper(subtipo), "DESENVOLVIMENTO DE (SOFTWARE|APLICATIVO)") ~
        "Desenvolvimento de Software/Aplicativo",
      TRUE ~ subtipo
    )
  )

# 6. Criando a nova variável subtipo_area
dados_processados <- dados_processados %>%
  mutate(
    subtipo_area = case_when(
      str_detect(toupper(natureza), "TRABALHO COMPLETO") ~
        "Trabalhos Completos Publicados em Anais de Congressos",
      str_detect(toupper(natureza), "ANAL[ÍI]TICA") ~
        "Processo/Tecnologia não Patenteável",
      str_detect(toupper(natureza), "PROCESSUAL") ~
        "Processo/Tecnologia não Patenteável",
      str_detect(toupper(natureza), "RESUMO") ~
        "Resumos Publicados em Anais de Congressos",
      str_detect(toupper(natureza), "COMPUTACIONAL") ~
        "Software/Aplicativo",
      str_detect(toupper(natureza), "COMPLETO") ~
        "Artigos Completos Publicados em Periódicos",
      str_detect(toupper(natureza), "RELAT[ÓO]RIO T[ÉE]CNICO") ~
        "Relatório Técnico Conclusivo",
      str_detect(toupper(natureza), "CONGRESSO|SEMIN[ÁA]RIO") ~
        "Apresentação de Trabalho",
      str_detect(toupper(natureza), "APERFEI[ÇC]OAMENTO") ~
        "Curso de Curta Duração",
      str_detect(toupper(natureza), "MANUAL") ~
        "Material Didático",
      TRUE ~ NA_character_
    )
  )

# 7. Convertendo todas as variáveis para factor
dados_finais <- dados_processados %>%
  mutate(across(everything(), as.factor))

# Tarefas adicionais para garantir dados válidos

# Removendo linhas com valores NA em variáveis essenciais
dados_finais <- dados_finais %>%
  filter(!is.na(id), !is.na(tipo), !is.na(subtipo))

# Verificando inconsistências entre tipo e subtipo
dados_finais <- dados_finais %>%
  mutate(
    tipo = case_when(
      subtipo %in% c("Artigo em Periódico", "Trabalho em Anais") ~ "Bibliográfica",
      subtipo %in% c(
        "Trabalhos Técnicos",
        "Desenvolvimento de Técnica",
        "Curso de Curta Duração",
        "Desenvolvimento de Material Didático e Instrucional",
        "Desenvolvimento de Software/Aplicativo"
      ) ~ "Técnica",
      TRUE ~ as.character(tipo)
    )
  ) %>%
  mutate(tipo = as.factor(tipo))


# Resumo dos dados processados
glimpse(dados_finais)


# Salva o arquivo processado
write_csv(dados_finais, arquivo_saida_csv)
write_rds(dados_finais, arquivo_saida_rds)

# ler o arquivo rds
path_rds <- "dados/limpos/producoes_concluintes.rds"
producoes_concluintes <- readr::read_rds(here(path_rds))

View(producoes_concluintes)




# Fim do script

