% =============================================================================
%  CABO VERDE 2026: A JORNADA DO ARQUIPELAGO
%  RPG de aventura interativo em texto (SWI-Prolog + XPCE)
%  Copa do Mundo FIFA 2026 - Canada / Mexico / Estados Unidos
%
%  COMO RODAR:
%    swipl copa2026.pl
%    ?- jogar.
%
%  Voce e o tecnico da selecao de Cabo Verde.
%  Conduza-os desde o Grupo H ate (quem sabe) o titulo mundial!
% =============================================================================

:- use_module(library(pce)).
:- use_module(library(lists)).
:- use_module(library(random)).

% =============================================================================
% 1. ESTADO DINAMICO
% =============================================================================

:- dynamic local_atual/1.
:- dynamic energia/1.            % 0-10
:- dynamic reputacao/1.          % 0-100 (imagem publica do tecnico)
:- dynamic moral/1.              % 0-100 (moral do plantel)
:- dynamic tatica/1.             % ofensiva | defensiva | equilibrada
:- dynamic fase/1.               % grupo | oitavas | quartas | semi | final | campeao
:- dynamic rodada_grupo/1.       % 1, 2, 3
:- dynamic historico/3.          % historico(Fase, SiglaOponente, Resultado)
:- dynamic classificacao/4.      % classificacao(Sigla, Pts, SG, GolsPro)
:- dynamic treino_feito/0.       % bonus de treino ativo para proximo jogo
:- dynamic analise_feita/1.      % analise_feita(SiglaOponente)
:- dynamic jogo_acabou/0.
:- dynamic janela_pce/1.

% =============================================================================
% 2. DADOS DO JOGO
% =============================================================================

% selecao(Sigla, NomeDisplay, Forca1a5, Bandeira)
selecao(caboverde,     'Cabo Verde',     2, '[CV]').
selecao(arabiasaudita, 'Arabia Saudita', 3, '[SA]').
selecao(uruguai,       'Uruguai',        4, '[UY]').
selecao(espanha,       'Espanha',        5, '[ES]').

% Calendario Grupo H (6 jogos, 3 por rodada)
% Rodada 1: CV x ESP (duelo dos extremos), KSA x URU
% Rodada 2: CV x URU (decisivo), ESP x KSA
% Rodada 3: CV x KSA (chance de fechar bem), ESP x URU
confronto_grupo(1, caboverde,     espanha).
confronto_grupo(1, arabiasaudita, uruguai).
confronto_grupo(2, caboverde,     uruguai).
confronto_grupo(2, espanha,       arabiasaudita).
confronto_grupo(3, caboverde,     arabiasaudita).
confronto_grupo(3, espanha,       uruguai).

% Oponentes nas fases eliminatorias (narrativa tematica)
% oponente_fase(Fase, Sigla, Forca, NomeDisplay, Bandeira)
oponente_fase(oitavas, curacao,   3, 'Curacao',   '[CR]').
oponente_fase(quartas, equador, 4, 'Equador', '[EQ]').
oponente_fase(semi,    costadomarfim,   5, 'Costa do Marfim',   '[CM]').
oponente_fase(final,   alemanha, 5, 'Alemanha', '[DE]').

% Jogadores destaque de Cabo Verde
% jogador(Sigla, Nome, Posicao, Habilidade)
jogador(garry,   'Garry Rodrigues', atacante, 8).
jogador(ryan,    'Ryan Mendes',     meia,     7).
jogador(stopira, 'Stopira',         zagueiro, 8).
jogador(vozinha, 'Vozinha',         goleiro,  7).
jogador(kenny,   'Kenny Rocha',     volante,  7).

% Locais e suas descricoes
local(hotel,
    'Hotel do Plantel - Selecao de Cabo Verde',
    'O lobby e simples mas acolhedor. Bandeiras do arquipelago decoram\c
 as paredes. Jogadores conversam animados nos corredores.\c
\nAcoes disponiveis: descansar. | motivar. | falar(Nome).\c
\nSaidas: campo_treino | sala_imprensa | estadio').

local(campo_treino,
    'Campo de Treino Oficial - Copa 2026',
    'Gramado verde, cones e coletes coloridos. O preparador fisico\c
 supervisiona os exercicios com rigor.\c
\nAcoes disponiveis: treinar. | tatica(T).\c
\nSaidas: hotel | sala_analise').

local(sala_analise,
    'Sala de Analise Tatica - Centro de Midia',
    'Telas com videos dos adversarios, lousa tatica e planilhas de dados.\c
 O analista de desempenho aguarda suas instrucoes.\c
\nAcoes disponiveis: analisar.\c
\nSaidas: campo_treino | hotel').

local(sala_imprensa,
    'Sala de Imprensa - Copa do Mundo 2026',
    'Dezenas de jornalistas de todo o mundo aguardam sua palavra sobre\c
 a surpreendente selecao de Cabo Verde.\c
\nAcoes disponiveis: entrevista.\c
\nSaidas: hotel | estadio').

local(estadio,
    'Estadio - Dia de Jogo',
    'A arena esta lotada e a torcida de Cabo Verde canta com a alma.\c
 E a hora da verdade.\c
\nAcoes disponiveis: jogar.\c
\nSaidas: hotel | sala_imprensa').

% Saidas entre locais
saida(hotel,         campo_treino,  campo_treino).
saida(hotel,         sala_imprensa, sala_imprensa).
saida(hotel,         estadio,       estadio).
saida(campo_treino,  hotel,         hotel).
saida(campo_treino,  sala_analise,  sala_analise).
saida(sala_analise,  campo_treino,  campo_treino).
saida(sala_analise,  hotel,         hotel).
saida(sala_imprensa, hotel,         hotel).
saida(sala_imprensa, estadio,       estadio).
saida(estadio,       hotel,         hotel).
saida(estadio,       sala_imprensa, sala_imprensa).

% =============================================================================
% 3. INICIALIZACAO
% =============================================================================

jogar :-
    inicializar_estado,
    intro,
    abrir_painel_xpce,
    loop_principal.

inicializar_estado :-
    retractall(local_atual(_)),   retractall(energia(_)),
    retractall(reputacao(_)),     retractall(moral(_)),
    retractall(tatica(_)),        retractall(fase(_)),
    retractall(rodada_grupo(_)),  retractall(historico(_,_,_)),
    retractall(classificacao(_,_,_,_)),
    retractall(treino_feito),     retractall(analise_feita(_)),
    retractall(jogo_acabou),
    asserta(local_atual(hotel)),
    asserta(energia(10)),
    asserta(reputacao(40)),
    asserta(moral(60)),
    asserta(tatica(equilibrada)),
    asserta(fase(grupo)),
    asserta(rodada_grupo(1)),
    forall(selecao(S, _, _, _), asserta(classificacao(S, 0, 0, 0))).

intro :-
    nl,
    writeln('================================================================'),
    writeln('  CABO VERDE 2026: A JORNADA DO ARQUIPELAGO'),
    writeln('  RPG de Aventura em Texto - Copa do Mundo FIFA 2026'),
    writeln('================================================================'),
    nl,
    writeln('Praia, Republica de Cabo Verde. Aeroporto Internacional.'),
    nl,
    writeln('A convocacao chegou de surpresa. Voce, treinador cabo-verdiano'),
    writeln('criado nas peladas da Ilha do Sal, acaba de receber a missao'),
    writeln('mais ousada do futebol moderno: conduzir a selecao de Cabo Verde'),
    writeln('em sua PRIMEIRA Copa do Mundo da historia.'),
    nl,
    writeln('O GRUPO H aguarda:'),
    writeln('  [ES] Espanha       - Atual campea europeia      (Forca 5/5)'),
    writeln('  [UY] Uruguai       - Garra Charrua implacavel   (Forca 4/5)'),
    writeln('  [SA] Arabia Saudita - Revelacao asiatica        (Forca 3/5)'),
    writeln('  [CV] CABO VERDE    - O sonho do arquipelago     (Forca 2/5)'),
    nl,
    writeln('Para se classificar voce precisa terminar entre os 2 primeiros'),
    writeln('do grupo, ou ser um dos 8 melhores terceiros colocados.'),
    nl,
    writeln('Cada decisao importa: treino, tatica, analise do adversario,'),
    writeln('moral do plantel e sua reputacao com a imprensa.'),
    nl,
    writeln('FASE 1 - Grupo H  (3 partidas)'),
    writeln('FASE 2 - Oitavas de Final vs Curacao'),
    writeln('FASE 3 - Quartas de Final vs Equador'),
    writeln('FASE 4 - Semifinal vs Costa do Marfim'),
    writeln('FASE 5 - FINAL vs Alemanha'),
    nl,
    writeln('Digite "ajuda." para ver todos os comandos.'),
    writeln('(Atencao: todo comando termina com ponto "." -- e Prolog!)'),
    nl.

% =============================================================================
% 4. PAINEL XPCE
% =============================================================================

abrir_painel_xpce :-
    ( janela_pce(_) -> true
    ; catch(criar_painel_xpce, Err,
            format('Aviso XPCE indisponivel (~w). Jogo continua em modo texto.~n', [Err]))
    ).

% BUG3 FIX: pce_dispatch([]) move o event loop XPCE para uma thread separada,
% liberando o stdin do terminal para read/1 sem interferencia (corrige o bug
% onde o jogador precisava apertar backspace antes de digitar comandos).
criar_painel_xpce :-
    new(W, picture('Cabo Verde 2026 - Painel do Tecnico')),
    send(W, size, size(650, 590)),
    asserta(janela_pce(W)),
    ignore(catch(pce_dispatch([]), _, true)),   % XPCE em thread propria
    atualizar_painel,
    send(W, open).

atualizar_painel :-
    catch(desenhar_painel, _, true).

desenhar_painel :-
    janela_pce(W), !,
    send(W, clear),
    % --- Titulo ---
    new(Tit, text('CABO VERDE 2026 - PAINEL DO TECNICO', center, bold)),
    send(Tit, font, font(helvetica, bold, 15)),
    send(W, display, Tit, point(20, 8)),
    nova_linha_h(W, 0, 30, 650),
    % --- Indicador de fase ---
    desenhar_fase(W, 20, 36),
    nova_linha_h(W, 0, 72, 650),
    % --- Coluna esquerda: tabela do grupo ---
    desenhar_tabela_grupo(W, 15, 80),
    % --- Divisor vertical central ---
    nova_linha_v(W, 335, 72, 355),
    % --- Coluna direita: historico ---
    desenhar_historico_xpce(W, 350, 80),
    % --- Linha horizontal media ---
    nova_linha_h(W, 0, 355, 650),
    % --- Mapa e status ---
    desenhar_mapa_xpce(W, 15, 363),
    nova_linha_v(W, 335, 355, 590),
    desenhar_status_xpce(W, 350, 363).
desenhar_painel.   % modo texto: nao faz nada

nova_linha_h(W, X1, Y, X2) :-
    new(L, line(X1, Y, X2, Y)), send(L, colour, colour(grey50)), send(W, display, L).
nova_linha_v(W, X, Y1, Y2) :-
    new(L, line(X, Y1, X, Y2)), send(L, colour, colour(grey50)), send(W, display, L).

% --- Indicador de fase ---
desenhar_fase(W, X, Y) :-
    fase(F),
    format(atom(FTxt), 'Fase atual: ~w', [F]),
    Fases = 'Grupo H  ->  Oitavas  ->  Quartas  ->  Semi  ->  FINAL',
    new(TF, text(FTxt, left, bold)), send(TF, font, font(helvetica, bold, 12)),
    send(TF, colour, colour(darkblue)), send(W, display, TF, point(X, Y)),
    new(TFases, text(Fases, left, normal)), send(TFases, font, font(screen, normal, 11)),
    send(W, display, TFases, point(X + 200, Y + 3)).

% --- Tabela do Grupo H ---
desenhar_tabela_grupo(W, X, Y) :-
    new(C, text('GRUPO H', left, bold)),
    send(C, font, font(helvetica, bold, 12)), send(W, display, C, point(X, Y)),
    nova_linha_h(W, X, Y+18, X+305),
    new(H, text('Selecao              Pts  SG  GP', left, normal)),
    send(H, font, font(screen, normal, 11)), send(W, display, H, point(X, Y+22)),
    selecoes_ordenadas(Lista),
    desenhar_linhas_grupo(W, Lista, X, Y+40, 1).

desenhar_linhas_grupo(_, [], _, _, _).
desenhar_linhas_grupo(W, [S-Pts-SG-GP|Resto], X, Y, Pos) :-
    selecao(S, Nome, _, Band),
    atom_length(Nome, Len), PadN is max(1, 20 - Len),
    length(Sp, PadN), maplist(=(' '), Sp), atomic_list_concat(Sp, Pad),
    format(atom(Txt), '~w ~w~w~w   ~w   ~w', [Band, Nome, Pad, Pts, SG, GP]),
    new(L, text(Txt, left, normal)), send(L, font, font(screen, normal, 11)),
    ( S == caboverde -> send(L, colour, colour(darkgreen)) ; true ),
    ( Pos =< 2 -> send(L, colour, colour(darkblue)) ; true ),
    ( S == caboverde, Pos =< 2 -> send(L, colour, colour(darkgreen)) ; true ),
    send(W, display, L, point(X, Y)),
    Y2 is Y + 18, Pos2 is Pos + 1,
    desenhar_linhas_grupo(W, Resto, X, Y2, Pos2).

% --- Historico de partidas ---
desenhar_historico_xpce(W, X, Y) :-
    new(C, text('HISTORICO DE PARTIDAS', left, bold)),
    send(C, font, font(helvetica, bold, 12)), send(W, display, C, point(X, Y)),
    nova_linha_h(W, X, Y+18, X+285),
    findall(F-Op-R, historico(F, Op, R), Hist),
    ( Hist == []
    -> ( new(T, text('Nenhuma partida ainda.', left, normal)),
         send(T, font, font(screen, normal, 11)), send(W, display, T, point(X, Y+25)) )
    ;  desenhar_linhas_hist(W, Hist, X, Y+25)
    ).

desenhar_linhas_hist(_, [], _, _).
desenhar_linhas_hist(W, [F-Op-Res|Resto], X, Y) :-
    nome_oponente(Op, NomeOp),
    format(atom(Txt), '~w | ~w | ~w', [F, NomeOp, Res]),
    new(L, text(Txt, left, normal)), send(L, font, font(screen, normal, 11)),
    resultado_cor(Res, Cor), send(L, colour, colour(Cor)),
    send(W, display, L, point(X, Y)),
    Y2 is Y + 18,
    desenhar_linhas_hist(W, Resto, X, Y2).

resultado_cor(vitoria, darkgreen).
resultado_cor(empate,  darkorange).
resultado_cor(derrota, red).

% --- Mini-mapa ---
desenhar_mapa_xpce(W, X, Y) :-
    new(C, text('LOCALIZACAO', left, bold)),
    send(C, font, font(helvetica, bold, 12)), send(W, display, C, point(X, Y)),
    Locais = [hotel-'Hotel do Plantel', campo_treino-'Campo de Treino',
              sala_analise-'Sala de Analise', sala_imprensa-'Sala de Imprensa',
              estadio-'Estadio'],
    desenhar_loc(W, Locais, X, Y+22).

desenhar_loc(_, [], _, _).
desenhar_loc(W, [Id-Nome|Resto], X, Y) :-
    local_atual(Atual),
    ( Atual == Id -> Pref = '>> ' ; Pref = '   ' ),
    format(atom(Txt), '~w~w', [Pref, Nome]),
    new(L, text(Txt, left, normal)), send(L, font, font(screen, normal, 12)),
    ( Atual == Id -> send(L, colour, colour(red)) ; true ),
    send(W, display, L, point(X, Y)),
    Y2 is Y + 22,
    desenhar_loc(W, Resto, X, Y2).

% --- Status do plantel ---
desenhar_status_xpce(W, X, Y) :-
    energia(En), moral(M), reputacao(Rep), tatica(T),
    new(C, text('STATUS DO PLANTEL', left, bold)),
    send(C, font, font(helvetica, bold, 12)), send(W, display, C, point(X, Y)),
    format(atom(TE), 'Energia   : ~w/5',   [En]),
    format(atom(TM), 'Moral     : ~w/100', [M]),
    format(atom(TR), 'Reputacao : ~w/100', [Rep]),
    format(atom(TT), 'Tatica    : ~w',     [T]),
    exibir_txt_status(W, TE, X, Y+22, black),
    ( M >= 70 ->
        CorM = darkgreen
    ; M >= 40 ->
        CorM = darkorange
    ; CorM = red
    ),
    exibir_txt_status(W, TM, X, Y+40, CorM),
    exibir_txt_status(W, TR, X, Y+58, black),
    exibir_txt_status(W, TT, X, Y+76, darkblue),
    % Badges de preparacao
    Y2 is Y + 98,
    ( treino_feito
    -> exibir_txt_status(W, '[TREINO FEITO]', X, Y2, darkgreen)
    ;  exibir_txt_status(W, '[sem treino]', X, Y2, grey50) ),
    Y3 is Y2 + 18,
    findall(A, analise_feita(A), Ans),
    ( Ans \= []
    -> ( atomic_list_concat(Ans, ',', AS),
         format(atom(TA), '[ANALISE: ~w]', [AS]),
         exibir_txt_status(W, TA, X, Y3, darkblue) )
    ;  exibir_txt_status(W, '[sem analise]', X, Y3, grey50) ).

exibir_txt_status(W, Txt, X, Y, Cor) :-
    new(L, text(Txt, left, normal)), send(L, font, font(screen, normal, 12)),
    send(L, colour, colour(Cor)), send(W, display, L, point(X, Y)).

% =============================================================================
% 5. LOOP PRINCIPAL
% =============================================================================

% PROTECAO: ignore/1 garante que uma falha inesperada em processar/1
% nao derrube o loop inteiro -- o jogo continua mesmo se uma acao falhar.
loop_principal :-
    ( jogo_acabou -> finalizar_jogo
    ; descrever_local_atual,
      ler_comando(Cmd),
      ignore(catch(processar(Cmd), Err,
                   format('Erro interno ao processar comando: ~w~n', [Err]))),
      loop_principal
    ).

% BUG3 FIX: read_term(user_input,...) le explicitamente do stdin do terminal,
% evitando que o stream seja redirecionado pelo event loop do XPCE.
ler_comando(Cmd) :-
    nl, write('> '), flush_output,
    catch(
        read_term(user_input, Cmd, [variable_names(_)]),
        _,
        (skip_line, Cmd = erro_leitura)
    ).

descrever_local_atual :-
    local_atual(Id),
    local(Id, Titulo, Desc),
    nl,
    format('--- ~w ---~n', [Titulo]),
    writeln(Desc), nl.

% =============================================================================
% 6. COMANDOS
% =============================================================================

processar(ajuda)          :- !, mostrar_ajuda.
processar(status)         :- !, mostrar_status.
processar(olhar)          :- !, descrever_local_atual.
processar(mapa)           :- !, abrir_painel_xpce, atualizar_painel.
processar(classificacao)  :- !, mostrar_tabela.
processar(historico)      :- !, mostrar_historico.
processar(ir(D))          :- !, mover(D).
processar(hotel)          :- !, mover(hotel).
processar(campo_treino)   :- !, mover(campo_treino).
processar(sala_analise)   :- !, mover(sala_analise).
processar(sala_imprensa)  :- !, mover(sala_imprensa).
processar(estadio)        :- !, mover(estadio).
processar(descansar)      :- !, acao_descansar.
processar(treinar)        :- !, acao_treinar.
processar(analisar)       :- !, acao_analisar.
processar(motivar)        :- !, acao_motivar.
processar(tatica(T))      :- !, acao_tatica(T).
processar(falar(J))       :- !, falar_com(J).
processar(entrevista)     :- !, acao_entrevista.
processar(jogar)          :- !, acao_jogar.
processar(avancar)        :- !, acao_avancar_terceiro.
processar(salvar)         :- !, salvar_jogo.
processar(carregar)       :- !, carregar_jogo.
processar(quit)           :- !, asserta(jogo_acabou).
processar(end_of_file)    :- !, asserta(jogo_acabou).
processar(erro_leitura)   :- !,
    writeln('Comando invalido. Lembre-se do ponto "." Ex: treinar.  tatica(ofensiva).').
processar(_) :-
    writeln('Nao entendi. Digite "ajuda." para ver os comandos disponiveis.').

mostrar_ajuda :-
    nl,
    writeln('===== COMANDOS (sempre com ponto final ".") ====='),
    nl,
    writeln('INFORMACAO:'),
    writeln('  ajuda.                  - esta lista'),
    writeln('  olhar.                  - re-descreve o local atual'),
    writeln('  status.                 - energia, moral, reputacao e tatica'),
    writeln('  classificacao.          - tabela atualizada do Grupo H'),
    writeln('  historico.              - seus resultados ate agora'),
    writeln('  mapa.                   - atualiza o painel grafico XPCE'),
    nl,
    writeln('NAVEGACAO:'),
    writeln('  hotel.                  - Hotel do Plantel'),
    writeln('  campo_treino.           - Campo de Treino'),
    writeln('  sala_analise.           - Sala de Analise Tatica'),
    writeln('  sala_imprensa.          - Sala de Imprensa'),
    writeln('  estadio.                - Estadio (para jogar)'),
    nl,
    writeln('ACOES:'),
    writeln('  descansar.              - recupera 10 de energia (hotel)'),
    writeln('  treinar.                - bonus na prox. partida (campo_treino, custo 2 en.)'),
    writeln('  analisar.               - estuda adversario (sala_analise, custo 1 en.)'),
    writeln('  motivar.                - discurso; +moral (hotel, custo 1 en.)'),
    writeln('  tatica(ofensiva).       - +ataque, mais risco (campo_treino)'),
    writeln('  tatica(defensiva).      - +defesa, menos gols sofridos (campo_treino)'),
    writeln('  tatica(equilibrada).    - balanceado (campo_treino)'),
    writeln('  falar(garry).           - conversa com Garry Rodrigues (hotel)'),
    writeln('  falar(ryan).            - conversa com Ryan Mendes (hotel)'),
    writeln('  falar(stopira).         - conversa com Stopira (hotel)'),
    writeln('  falar(vozinha).         - conversa com Vozinha (hotel)'),
    writeln('  falar(kenny).           - conversa com Kenny Rocha (hotel)'),
    writeln('  entrevista.             - coletiva de imprensa (sala_imprensa)'),
    writeln('  jogar.                  - disputa a proxima partida (estadio)'),
    writeln('  avancar.                - avanca para as eliminatorias'),
    nl,
    writeln('SISTEMA:'),
    writeln('  salvar.   carregar.   quit.'),
    nl.

mostrar_status :-
    energia(En), moral(M), reputacao(Rep), tatica(T),
    fase(F), rodada_grupo(R),
    nl,
    writeln('--- STATUS ATUAL ---'),
    format('Fase          : ~w~n', [F]),
    ( F == grupo -> format('Rodada        : ~w/3~n', [R]) ; true ),
    format('Energia       : ~w/10~n', [En]),
    format('Moral         : ~w/100~n', [M]),
    format('Reputacao     : ~w/100~n', [Rep]),
    format('Tatica        : ~w~n', [T]),
    ( treino_feito
    -> writeln('[OK] Bonus de treino ativo para a proxima partida.')
    ;  writeln('[--] Nenhum treino realizado ainda para esta partida.') ),
    findall(A, analise_feita(A), Ans),
    format('Analises feitas: ~w~n', [Ans]),
    nl.

mostrar_tabela :-
    nl, writeln('--- CLASSIFICACAO GRUPO H ---'),
    writeln('Pos  Selecao              Pts  SG  GP'),
    writeln('-------------------------------------------'),
    selecoes_ordenadas(Lista),
    mostrar_linhas_tabela(Lista, 1).

mostrar_linhas_tabela([], _).
mostrar_linhas_tabela([S-Pts-SG-GP|Resto], Pos) :-
    selecao(S, Nome, _, Band),
    ( Pos =< 2 -> Qual = 'Q' ; Qual = ' ' ),
    format('~w~w  ~w ~w~30|~w~35|~w~40|~w~n', [Qual, Pos, Band, Nome, Pts, SG, GP]),
    Pos2 is Pos + 1,
    mostrar_linhas_tabela(Resto, Pos2).

mostrar_historico :-
    findall(F-Op-R, historico(F, Op, R), H),
    nl,
    ( H == []
    -> writeln('Nenhuma partida disputada ainda.')
    ;  writeln('--- HISTORICO DE PARTIDAS ---'),
       forall(member(F-Op-Res, H),
              ( nome_oponente(Op, NomeOp),
                format('~w | vs ~w | ~w~n', [F, NomeOp, Res]) ))
    ), nl.

% =============================================================================
% 7. MOVIMENTO
% =============================================================================

mover(Dest) :-
    local_atual(Atual),
    ( saida(Atual, Dest, Destino)
    -> retractall(local_atual(_)), asserta(local_atual(Destino)),
       gastar_energia(1), atualizar_painel
    ;  format('Nao e possivel ir para "~w" daqui.~n', [Dest])
    ).

gastar_energia(Q) :-
    retract(energia(E)),
    E2 is max(0, E - Q),
    asserta(energia(E2)),
    ( E2 =:= 0
    -> writeln('*** ENERGIA ZERADA! Va ao hotel e descanse antes de continuar. ***')
    ;  true
    ).

% =============================================================================
% 8. ACOES DO TECNICO
% =============================================================================

acao_descansar :-
    local_atual(hotel), !,
    retractall(energia(_)), asserta(energia(10)),
    writeln('Noite de sono reparador. O plantel acorda renovado.'),
    writeln('Energia totalmente recuperada! (10/10)'),
    atualizar_painel.
acao_descansar :-
    writeln('Voce so pode descansar no hotel. Use: hotel.').

acao_treinar :-
    local_atual(campo_treino), !,
    ( treino_feito
    -> writeln('O plantel ja treinou para esta partida. Poupe energia para o dia do jogo.')
    ;  energia(E), E >= 2
    -> gastar_energia(2), asserta(treino_feito),
       writeln('Treino intenso de 2 horas! Os jogadores saem suados e confiantes.'),
       writeln('[BONUS DE TREINO ATIVO para a proxima partida]'),
       mudar_moral(5), atualizar_painel
    ;  writeln('Sem energia suficiente para treinar (minimo: 2). Descanse no hotel.')
    ).
acao_treinar :-
    writeln('Va ao campo de treino. Use: campo_treino.').

acao_analisar :-
    local_atual(sala_analise), !,
    ( proximo_oponente(Op)
    -> ( analise_feita(Op)
       -> ( nome_oponente(Op, NomeOp),
            format('Voce ja analisou ~w. Bonus ja ativo.~n', [NomeOp]) )
       ;  energia(E), E >= 1
       -> ( gastar_energia(1), asserta(analise_feita(Op)),
            nome_oponente(Op, NomeOp),
            format('Analise de ~w concluida!~n', [NomeOp]),
            format('Voce identificou os padroes ofensivos e defensivos de ~w.~n', [NomeOp]),
            writeln('[BONUS DE ANALISE ATIVO para a proxima partida]'),
            atualizar_painel )
       ;  writeln('Sem energia para analisar (minimo: 1). Descanse no hotel.')
       )
    ;  writeln('Nao ha proximo oponente definido no momento.')
    ).
acao_analisar :-
    writeln('Va a sala de analise. Use: sala_analise.').

% BUG1+2 FIX: acao_motivar nunca falha (if-then-else sem cortes soltos)
acao_motivar :-
    ( local_atual(hotel)
    -> ( energia(E), E >= 1
       -> ( gastar_energia(1),
            random_member(Frase, [
                'Voce discursa com emocao: "Nao viemos a esta Copa para passeio. Viemos para HISTORIA!"',
                'Voce relembra a trajetoria: "Da pelada na Ilha do Sal ate aqui -- cada quilometro valeu!"',
                'Voce fala sobre as ilhas: "Nossa torcida viajou o Atlantico para nos ver!"',
                'Voce le uma mensagem dos filhos dos jogadores. Lagrimas no vestiario!'
            ]),
            writeln(Frase),
            mudar_moral(10),
            moral(M),
            format('Moral do plantel: +10 (agora em ~w/100)~n', [M]),
            atualizar_painel )
       ;   writeln('Sem energia suficiente para motivar (minimo: 1). Descanse no hotel.') )
    ;   writeln('Voce so pode motivar o plantel no hotel. Use: hotel.') ).

acao_tatica(T) :-
    ( T = ofensiva ; T = defensiva ; T = equilibrada ), !,
    ( local_atual(campo_treino)
    -> retractall(tatica(_)), asserta(tatica(T)),
       format('Tatica ajustada para: ~w~n', [T]),
       descricao_tatica(T), atualizar_painel
    ;  writeln('Ajuste sua tatica no campo de treino. Use: campo_treino.')
    ).
acao_tatica(_) :-
    writeln('Tatica invalida. Use: tatica(ofensiva). | tatica(defensiva). | tatica(equilibrada).').

descricao_tatica(ofensiva) :-
    writeln('Pressao alta e atacantes adiantados. Mais gols marcados -- e mais sofridos.').
descricao_tatica(defensiva) :-
    writeln('Bloco baixo e contra-ataques certeiros. Menos gols sofridos -- e menos marcados.').
descricao_tatica(equilibrada) :-
    writeln('Equilibrio entre ataque e defesa. A escolha mais segura para qualquer adversario.').

acao_entrevista :-
    local_atual(sala_imprensa), !,
    gastar_energia(1),
    random_member(Tipo, [boa, boa, neutra, ruim]),
    reagir_entrevista(Tipo), atualizar_painel.
acao_entrevista :-
    writeln('Va a sala de imprensa. Use: sala_imprensa.').

reagir_entrevista(boa) :-
    writeln('Voce fala com paixao e seguranca. A sala aplaude ao final!'),
    writeln('"Uma revelacao de Copa!" -- ESPN Internacional.'),
    mudar_reputacao(8).
reagir_entrevista(neutra) :-
    writeln('Entrevista correta. Sem grandes destaque, mas sem erros.'),
    mudar_reputacao(2).
reagir_entrevista(ruim) :-
    writeln('Voce menciona uma estatistica errada. Os jornalistas se entreolham...'),
    writeln('"Tecnico de Cabo Verde confunde dados" -- titular de jornal.'),
    mudar_reputacao(-5).

mudar_moral(D) :-
    retract(moral(M)), M2 is max(0, min(100, M + D)), asserta(moral(M2)).

mudar_reputacao(D) :-
    retract(reputacao(R)), R2 is max(0, min(100, R + D)), asserta(reputacao(R2)).

% =============================================================================
% 9. NPCs - JOGADORES DE CABO VERDE
% =============================================================================

falar_com(J) :-
    local_atual(hotel),
    jogador(J, _, _, _), !,
    dialogo_jogador(J).
falar_com(J) :-
    jogador(J, _, _, _), !,
    writeln('Os jogadores estao fora de alcance agora. Encontre-os no hotel. Use: hotel.').
falar_com(J) :-
    format('Nao ha nenhum "~w" no plantel. Tente: garry, ryan, stopira, vozinha, kenny.~n', [J]).

dialogo_jogador(garry) :-
    writeln('Garry Rodrigues: "Treinador, passei anos na Holanda. Todo dia acordava'),
    writeln('pensando numa Copa do Mundo. Agora chegou. Pode contar comigo."'),
    mudar_moral(4).
dialogo_jogador(ryan) :-
    writeln('Ryan Mendes: "Nosso povo nunca acreditou que um dia chegariamos aqui.'),
    writeln('Vamos provar que Cabo Verde e grande demais para qualquer grupo."'),
    mudar_moral(3).
dialogo_jogador(stopira) :-
    writeln('Stopira: "Na defesa eu sou o muro, treinador.'),
    writeln('Podem vir com Lewandowski, Benzema ou quem for. Nao passa."'),
    mudar_moral(3).
dialogo_jogador(vozinha) :-
    writeln('Vozinha: "Cada penalti que eu pegar sera dedicado as dez ilhas.'),
    writeln('Minha familia esta na aldeia assistindo pela televisao do vizinho."'),
    mudar_moral(4).
dialogo_jogador(kenny) :-
    writeln('Kenny Rocha: "Meu irmao ficou no cais de Praia me vendo partir.'),
    writeln('Prometi que ia trazer algo especial de volta. Vou cumprir."'),
    mudar_moral(5).

% =============================================================================
% 10. SIMULACAO DE PARTIDAS
% =============================================================================

% Determina quem e o proximo oponente de Cabo Verde
proximo_oponente(Op) :-
    fase(grupo), rodada_grupo(R),
    confronto_grupo(R, caboverde, Op), !.
proximo_oponente(Op) :-
    fase(F), F \= grupo,
    oponente_fase(F, Op, _, _, _), !.

acao_jogar :-
    local_atual(estadio), !,
    ( proximo_oponente(Op)
    -> fase(F),
       ( F == grupo
       -> jogar_partida_grupo(Op)
       ;  jogar_partida_eliminatoria(F, Op)
       )
    ;  writeln('Nao ha partida agendada. Verifique a fase atual com status.')
    ).
acao_jogar :-
    writeln('Va ao estadio para disputar a partida. Use: estadio.').

% ---- Partida da Fase de Grupos ----
jogar_partida_grupo(Op) :-
    rodada_grupo(R),
    selecao(Op, NomeOp, _, BandOp),
    nl,
    writeln('================================================================'),
    format('=== RODADA ~w DO GRUPO H ===~n', [R]),
    format('  [CV] CABO VERDE  x  ~w ~w~n', [NomeOp, BandOp]),
    writeln('================================================================'),
    mostrar_preparacao,
    simular_cv(Op, GolsCV, GolsOp),
    nl,
    format('  PLACAR FINAL: Cabo Verde ~w x ~w ~w~n', [GolsCV, GolsOp, NomeOp]),
    registrar_resultado(grupo, Op, GolsCV, GolsOp),
    atualizar_tabela(caboverde, GolsCV, GolsOp),
    atualizar_tabela(Op, GolsOp, GolsCV),
    % Jogo paralelo desta rodada
    confronto_grupo(R, OutroA, OutroB),
    OutroA \= caboverde, OutroB \= caboverde,
    simular_paralelo(OutroA, OutroB),
    % Avanca rodada e limpa bonus
    R2 is R + 1,
    retractall(rodada_grupo(_)), asserta(rodada_grupo(R2)),
    retractall(treino_feito), retractall(analise_feita(_)),
    ( R2 > 3
    -> verificar_classificacao
    ;  format('Proxima partida e a Rodada ~w. Prepare-se!~n', [R2])
    ),
    atualizar_painel.

mostrar_preparacao :-
    writeln('--- PREPARACAO ---'),
    ( treino_feito -> writeln('  [+] Bonus de treino ativo') ; true ),
    findall(A, analise_feita(A), Ans),
    ( Ans \= [] -> format('  [+] Analise feita: ~w~n', [Ans]) ; true ),
    moral(M), format('  Moral do plantel: ~w/100~n', [M]),
    tatica(T), format('  Tatica: ~w~n', [T]), nl.

simular_paralelo(A, B) :-
    selecao(A, NA, _, _), selecao(B, NB, _, _),
    random_between(0, 4, GA), random_between(0, 4, GB),
    format('  [Jogo paralelo] ~w ~w x ~w ~w~n', [NA, GA, GB, NB]),
    atualizar_tabela(A, GA, GB),
    atualizar_tabela(B, GB, GA).

% ---- Partida Eliminatoria ----
jogar_partida_eliminatoria(Fase, Op) :-
    oponente_fase(Fase, Op, _, NomeOp, BandOp),
    nl,
    nome_fase_display(Fase, NomeFase),
    writeln('================================================================'),
    format('=== ~w ===~n', [NomeFase]),
    format('  [CV] CABO VERDE  x  ~w ~w~n', [NomeOp, BandOp]),
    writeln('================================================================'),
    mostrar_preparacao,
    simular_cv(Op, GolsCV, GolsOp),
    nl,
    format('  PLACAR 90min: Cabo Verde ~w x ~w ~w~n', [GolsCV, GolsOp, NomeOp]),
    ( GolsCV > GolsOp
    -> avancar_fase(Fase, Op, GolsCV, GolsOp)
    ; GolsCV =:= GolsOp
    -> prorrogacao_e_penaltis(Fase, Op, GolsCV, GolsOp)
    ; ser_eliminado(Fase, Op, GolsCV, GolsOp)
    ),
    retractall(treino_feito), retractall(analise_feita(_)),
    atualizar_painel.

avancar_fase(Fase, Op, GCV, GOp) :-
    registrar_resultado(Fase, Op, GCV, GOp),
    proxima_fase(Fase, PF),
    ( PF == campeao
    -> ( writeln(''), writeln('VOCE E CAMPEAO DO MUNDO! CABO VERDE CONQUISTOU A COPA 2026!'),
       retractall(fase(_)), asserta(fase(campeao)), asserta(jogo_acabou) )
    ;  ( writeln(''), writeln('CABO VERDE AVANCA DE FASE!!!'),
         nome_fase_display(PF, NPF),
         format('Proxima etapa: ~w!~n', [NPF]),
         mudar_moral(15), mudar_reputacao(10),
         retractall(fase(_)), asserta(fase(PF)) )
    ).

prorrogacao_e_penaltis(Fase, Op, GCV, GOp) :-
    writeln('Empate no tempo regulamentar! Prorrogacao...'),
    random_member(Pend, [cv_vence, cv_perde, cv_perde]),   % 1/3 de chance CV
    ( Pend = cv_vence
    -> ( writeln('CABO VERDE VENCE NOS PENALTIS!!!'),
         writeln('Vozinha defende o penalti decisivo! O estadio explode!'),
         avancar_fase(Fase, Op, GCV, GOp) )
    ;  ( writeln('Derrota nos penaltis. A jornada chega ao fim.'),
         registrar_resultado(Fase, Op, GCV, GOp),
         asserta(jogo_acabou) )
    ).

ser_eliminado(Fase, Op, GCV, GOp) :-
    registrar_resultado(Fase, Op, GCV, GOp),
    writeln('Cabo Verde foi eliminado. A jornada chega ao fim.'),
    asserta(jogo_acabou).

nome_fase_display(oitavas, 'OITAVAS DE FINAL').
nome_fase_display(quartas, 'QUARTAS DE FINAL').
nome_fase_display(semi,    'SEMIFINAL').
nome_fase_display(final,   'GRANDE FINAL - COPA DO MUNDO 2026').

proxima_fase(grupo,   oitavas).
proxima_fase(oitavas, quartas).
proxima_fase(quartas, semi).
proxima_fase(semi,    final).
proxima_fase(final,   campeao).

% ---- Mecanica central de simulacao ----
% Forca CV base = 2. Bonus: treino +1, analise +1, moral alto +1.
% Tatica: ofensiva +1 ataque; defensiva -1 oponente.
% Resultado: random_between(0, MaxGols, Gols) para cada time.

simular_cv(Op, GolsCV, GolsOp) :-
    forca_op(Op, ForcaOp),
    moral(M),
    BonusMoral is (M - 50) // 25,            % -2 a +2
    ( treino_feito    -> BT = 1 ; BT = 0 ),
    ( analise_feita(Op) -> BA = 1 ; BA = 0 ),
    ForcaCVbase is 2 + BonusMoral + BT + BA,
    tatica(T),
    ajuste_tatica(T, ForcaCVbase, ForcaOp, FCV, FOP),
    MaxCV is max(1, min(FCV, 5)),
    MaxOp is max(1, min(FOP, 6)),
    random_between(0, MaxCV, GolsCV),
    random_between(0, MaxOp, GolsOp),
    format('  [Forca efetiva CV: ~w | ~w: ~w -- escala 0-6]~n', [MaxCV, Op, MaxOp]).

forca_op(Op, F) :-
    ( selecao(Op, _, F, _)             -> true
    ; oponente_fase(_, Op, F, _, _)    -> true
    ; F = 3
    ).

ajuste_tatica(ofensiva,    FCV, FOp, FCV2, FOp) :- FCV2 is FCV + 1.
ajuste_tatica(defensiva,   FCV, FOp, FCV,  FOp2):- FOp2 is max(1, FOp - 1).
ajuste_tatica(equilibrada, FCV, FOp, FCV,  FOp).

registrar_resultado(Fase, Op, GCV, GOp) :-
    ( GCV > GOp  -> Res = vitoria,  mudar_moral( 12), mudar_reputacao( 10)
    ; GCV =:= GOp -> Res = empate,  mudar_moral(  4), mudar_reputacao(  3)
    ;               Res = derrota, mudar_moral(-10), mudar_reputacao( -5)
    ),
    asserta(historico(Fase, Op, Res)),
    format('  Resultado oficial: ~w~n', [Res]).

atualizar_tabela(Time, GolsPro, GolsContra) :-
    ( retract(classificacao(Time, Pts, SG, GP)) -> true ; Pts=0, SG=0, GP=0 ),
    ( GolsPro > GolsContra  -> PG = 3
    ; GolsPro =:= GolsContra -> PG = 1
    ;                           PG = 0 ),
    Pts2 is Pts + PG,
    SG2  is SG + (GolsPro - GolsContra),
    GP2  is GP + GolsPro,
    asserta(classificacao(Time, Pts2, SG2, GP2)).

% ---- Verificar classificacao apos 3 rodadas ----
verificar_classificacao :-
    nl, writeln('================================================================'),
    writeln('=== FASE DE GRUPOS ENCERRADA ==='),
    mostrar_tabela,
    selecoes_ordenadas([P1-_-_-_, P2-_-_-_ | _]),
    ( P1 == caboverde ; P2 == caboverde
    -> ( writeln(''),
         writeln('CABO VERDE CLASSIFICADO COMO UM DOS DOIS PRIMEIROS DO GRUPO H!!!'),
         writeln('Historia feita! Primeira classificacao para knockouts da historia!'),
         mudar_moral(20), mudar_reputacao(15),
         retractall(fase(_)), asserta(fase(oitavas)) )
    ;  ( nl,
         writeln('Cabo Verde terminou em 3o ou 4o lugar.'),
         classificacao(caboverde, Pts, _, _),
         ( Pts >= 3
         -> ( writeln('Com 3+ pontos, podemos ser um dos melhores terceiros colocados!'),
              writeln('Use "avancar." para tentar a classificacao como 3o lugar.') )
         ;  ( writeln('Sem pontos suficientes. A jornada historica termina aqui.'),
              writeln('Mas Cabo Verde colocou o arquipelago no mapa do futebol mundial!'),
              asserta(jogo_acabou) ) ) )
    ).

% Avanca como 3o lugar qualificado
acao_avancar_terceiro :-
    fase(grupo), !,
    classificacao(caboverde, Pts, _, _),
    ( Pts >= 3
    -> ( retractall(fase(_)), asserta(fase(oitavas)),
         writeln('Cabo Verde avanca para as eliminatorias!'),
         writeln('As Oitavas de Final aguardam! Va ao estadio.'),
         mudar_moral(10) )
    ;  writeln('Pontos insuficientes para avancar.')
    ).
acao_avancar_terceiro :-
    writeln('Comando valido apenas apos terminar a fase de grupos.').

% ---- Ordenacao da tabela ----
comparar_grupo(Ord, Pts1-SG1-GP1-S1, Pts2-SG2-GP2-S2) :-
    ( Pts1 > Pts2   -> Ord = (<)
    ; Pts1 < Pts2   -> Ord = (>)
    ; SG1  > SG2    -> Ord = (<)
    ; SG1  < SG2    -> Ord = (>)
    ; GP1  > GP2    -> Ord = (<)
    ; GP1  < GP2    -> Ord = (>)
    ; compare(Ord, S1, S2)
    ).

selecoes_ordenadas(Ordenada) :-
    findall(Pts-SG-GP-S, classificacao(S, Pts, SG, GP), Lista),
    predsort(comparar_grupo, Lista, OrdTmp),
    findall(S-Pts-SG-GP, member(Pts-SG-GP-S, OrdTmp), Ordenada).

% ---- Helper de nome ----
nome_oponente(Op, Nome) :-
    ( selecao(Op, Nome, _, _)          -> true
    ; oponente_fase(_, Op, _, Nome, _) -> true
    ; atom_string(Op, Nome)
    ).

% =============================================================================
% 11. ENCERRAMENTO DO JOGO
% =============================================================================

finalizar_jogo :-
    nl,
    writeln('================================================================'),
    fase(F),
    ( F == campeao -> encerramento_campeao
    ;                 encerramento_eliminado(F)
    ),
    nl,
    mostrar_historico,
    reputacao(Rep),
    format('Reputacao final como tecnico: ~w/100~n', [Rep]),
    nl,
    avaliar_tecnico(Rep),
    fechar_painel_xpce,
    nl,
    writeln('Obrigado por jogar CABO VERDE 2026: A JORNADA DO ARQUIPELAGO!'),
    nl.

encerramento_campeao :-
    writeln('  CABO VERDE E CAMPEAO DO MUNDO 2026!!!!'),
    writeln('  Das ilhas do Atlantico para o topo do futebol mundial.'),
    writeln('  Uma historia que sera contada por geracoes e geracoes.'),
    writeln('  Garry, Ryan, Stopira, Vozinha, Kenny -- herois eternos!').

encerramento_eliminado(grupo) :-
    writeln('  Cabo Verde foi eliminado na Fase de Grupos.'),
    writeln('  Mas participar da Copa ja e uma conquista historica.'),
    writeln('  O futebol cabo-verdiano nunca mais sera o mesmo.').
encerramento_eliminado(oitavas) :-
    writeln('  Cabo Verde chegou as Oitavas de Final da Copa do Mundo!'),
    writeln('  Uma campanha incrivel que emocionou o planeta inteiro.').
encerramento_eliminado(quartas) :-
    writeln('  CABO VERDE NAS QUARTAS DE FINAL DA COPA DO MUNDO!!!'),
    writeln('  O mundo inteiro se rendeu ao futebol bonito das ilhas.').
encerramento_eliminado(semi) :-
    writeln('  CABO VERDE NA SEMIFINAL DA COPA DO MUNDO!!!'),
    writeln('  Uma das maiores zebras da historia do futebol mundial.').
encerramento_eliminado(final) :-
    writeln('  CABO VERDE NA GRANDE FINAL DA COPA DO MUNDO!'),
    writeln('  Vice-campeao mundial -- mas herois absolutos do esporte.').
encerramento_eliminado(_) :-
    writeln('  A jornada historica de Cabo Verde chegou ao fim.').

avaliar_tecnico(R) :- R >= 85, !,
    writeln('LENDA ABSOLUTA. Seu nome sera escrito em ouro na historia de Cabo Verde.').
avaliar_tecnico(R) :- R >= 65, !,
    writeln('EXCELENTE trabalho tecnico. O futebol cabo-verdiano tem muito orgulho de voce.').
avaliar_tecnico(R) :- R >= 45, !,
    writeln('Boa campanha. Muito a construir. A proximo geracao agradece.').
avaliar_tecnico(_) :-
    writeln('O percurso foi duro. Mas toda grande historia comeca em algum lugar.').

fechar_painel_xpce :-
    ( janela_pce(W)
    -> catch(send(W, destroy), _, true), retractall(janela_pce(_))
    ;  true
    ).

% =============================================================================
% 12. SALVAR / CARREGAR
% =============================================================================

arquivo_save('copa2026_save.pl').

salvar_jogo :-
    arquivo_save(F),
    open(F, write, S),
    forall(fato_salvavel(Ft), (writeq(S, Ft), write(S, '.'), nl(S))),
    close(S),
    format('Jogo salvo em ~w~n', [F]).

fato_salvavel(local_atual(L))          :- local_atual(L).
fato_salvavel(energia(E))              :- energia(E).
fato_salvavel(reputacao(R))            :- reputacao(R).
fato_salvavel(moral(M))                :- moral(M).
fato_salvavel(tatica(T))               :- tatica(T).
fato_salvavel(fase(F))                 :- fase(F).
fato_salvavel(rodada_grupo(R))         :- rodada_grupo(R).
fato_salvavel(historico(A,B,C))        :- historico(A,B,C).
fato_salvavel(classificacao(S,P,SG,GP)):- classificacao(S,P,SG,GP).
fato_salvavel(treino_feito)            :- treino_feito.
fato_salvavel(analise_feita(A))        :- analise_feita(A).

carregar_jogo :-
    arquivo_save(F),
    ( exists_file(F)
    -> retractall(local_atual(_)), retractall(energia(_)),
       retractall(reputacao(_)),   retractall(moral(_)),
       retractall(tatica(_)),      retractall(fase(_)),
       retractall(rodada_grupo(_)),retractall(historico(_,_,_)),
       retractall(classificacao(_,_,_,_)),
       retractall(treino_feito),   retractall(analise_feita(_)),
       consult(F),
       writeln('Jogo carregado com sucesso!'), atualizar_painel
    ;  writeln('Nenhum arquivo de save encontrado.')
    ).

% =============================================================================
% FIM - Execute: ?- jogar.
% =============================================================================
