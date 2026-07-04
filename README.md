# Cabo Verde 2026: A Jornada do Arquipélago

RPG de aventura em texto desenvolvido em **SWI-Prolog**, com painel
gráfico em **XPCE**. Você assume o papel do técnico da seleção de **Cabo
Verde** e tenta conduzir o país à conquista da Copa do Mundo FIFA 2026.

## Requisitos

-   SWI-Prolog 10+
-   XPCE (incluído na instalação padrão do SWI-Prolog para Windows)

## Como executar

``` bash
swipl caboverde2026.pl
```

Depois:

``` prolog
?- jogar.
```

O painel gráfico XPCE é aberto automaticamente. Caso o ambiente não
tenha suporte gráfico, o jogo continua normalmente em modo texto.

## Mecânicas

-   Exploração de locais (hotel, campo de treino, sala de análise,
    imprensa e estádio)
-   Energia, moral, reputação e tática
-   Treinos, entrevistas e análise dos adversários
-   Fase de grupos completa
-   Mata-mata: Oitavas, Quartas, Semifinal e Final
-   Painel gráfico mostrando classificação, histórico, localização e
    status
-   Sistema de salvar/carregar

## Comandos

  -----------------------------------------------------------------------
  Comando                         Descrição
  ------------------------------- ---------------------------------------
  `ajuda.`                        Lista os comandos

  `status.`                       Exibe os atributos do treinador

  `olhar.`                        Descreve o local atual

  `classificacao.`                Mostra a tabela do Grupo H

  `historico.`                    Exibe as partidas disputadas

  `hotel.` `campo_treino.`        Movimentação
  `sala_analise.`                 
  `sala_imprensa.` `estadio.`     

  `descansar.`                    Recupera energia

  `treinar.`                      Ativa bônus de treino

  `analisar.`                     Analisa o próximo adversário

  `motivar.`                      Aumenta a moral do elenco

  `tatica(ofensiva).`             Define a estratégia

  `falar(garry).`                 Conversa com jogadores

  `entrevista.`                   Coletiva de imprensa

  `jogar.`                        Disputa a próxima partida

  `avancar.`                      Tenta classificação como melhor
                                  terceiro

  `salvar.` / `carregar.`         Salva ou carrega o jogo

  `quit.`                         Encerra o jogo
  -----------------------------------------------------------------------

## Objetivo

Sobreviver à fase de grupos e levar Cabo Verde até a final da Copa do
Mundo administrando preparação, moral, energia e reputação.

## Estrutura

-   Fatos dinâmicos para o estado do jogo
-   Simulação de partidas
-   Sistema de classificação
-   Interface XPCE
-   Persistência em arquivo `.pl`
