


# carrega os pacotes
library(pdftools)
library(here)


# importar a capa e o relatorio

capa <- here::here("capa.pdf")
relatorio <- here::here("relatorio_autoavaliacao.pdf")

# fundir os arquivos
pdf_combine(c(capa, relatorio),
            output = here::here("relatorio_autoavaliacao_com_capa.pdf"))