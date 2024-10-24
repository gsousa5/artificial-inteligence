globals [
  total-ataques
  total-reparacoes
  posto-carregamento-patch  ;; Patch do único posto de carregamento
  tartaruga-timer           ;; Timer para controle de aparição de tartarugas
  total-lixo-consumido
]

breed [cleaners cleaner]
breed [polluters polluter]
breed [crabs crab]
breed [water-turtles water-turtle]  ;; Breed de tartarugas

cleaners-own [
  energia
  num-residuos
  tempo-em-recarga
  ataque-contador
  turbo-mode-active
]
crabs-own [
  ataque-contador
]

polluters-own [
  probabilidade-deposito
]

water-turtles-own [  ;; Adicionando num-residuos para a breed de tartarugas
  energia        ;; Energia da tartaruga
  tempo-de-vida  ;; Tempo de vida da tartaruga
  num-residuos   ;; Variável adicionada para contar resíduos
]

patches-own [residuo? cor-residuo obstaculo? duna? agua? posto-carregamento?]  ;; Variável para o posto de carregamento

to setup
  clear-all
  reset-ticks

  ;; Inicializar os contadores
  set total-ataques 0
  set total-reparacoes 0
  set tartaruga-timer 0  ;; Inicializar o timer das tartarugas
  set total-lixo-consumido 0  ;; Inicializa o total de lixo consumido

  ;; Inicializar ambiente com células limpas
  ask patches [
    set pcolor orange + 4
    set residuo? false
    set obstaculo? false
    set duna? false
    set agua? false
    set posto-carregamento? false
    set cor-residuo orange + 4
  ]

  setup-agua

  ;; Criar Cleaners, Polluters, Crabs e Tartarugas
  create-cleaners slider-numero-cleaners [
    setxy min-pxcor min-pycor
    set color green
    set energia slider-energia
    set num-residuos 0
    set tempo-em-recarga 0
    set ataque-contador 0
    set turbo-mode-active false
    set shape "ufo top"
  ]

  ;; Criar Polluters
  create-polluters 3 [
    setxy random-xcor random-ycor
    set color red
    set shape "person"

    ;; Definir probabilidades de depósito diretamente para cada polluter
    if who mod 3 = 0 [ set probabilidade-deposito slider-probabilidade-polluter1 ]
    if who mod 3 = 1 [ set probabilidade-deposito slider-probabilidade-polluter2 ]
    if who mod 3 = 2 [ set probabilidade-deposito slider-probabilidade-polluter3 ]

    ;; Movimentar para um patch não-água, se o patch inicial for água
    if [agua?] of patch-here [
      move-to one-of patches with [not agua?]
    ]
  ]

  let numero-crabs slider-numero-crabs
  create-crabs numero-crabs [
    setxy random-xcor random-ycor
    set color brown
    set shape "crab"
    set size 2
    set ataque-contador 0
  ]

  setup-depositos
  setup-obstaculos
  setup-dunas
  setup-postos-carregamento  ;; Setup para o único posto de carregamento

  reset-ticks
end

to setup-agua
  ask patches with [pycor > max-pycor * 0.66] [
    set pcolor blue - 2
    set agua? true
  ]
end

to mover-cleaner
  ask cleaners [
    let distancia-para-posto distance posto-carregamento-patch

    ifelse energia <= distancia-para-posto + 5 [
      mover-para-posto-carregamento  ;; Chamada para mover até o único posto de carregamento
    ] [
      rt random 360

      if [obstaculo?] of patch-ahead 1 [
        rt random 180
      ]

      ;; Verificar se está em uma duna e ajustar a velocidade
      ifelse [duna?] of patch-here [
        ifelse turbo-mode-active [
          ;; Limpar área 4x4 quando turbo está ativo
          limpar-area-4x4
          set energia energia - 8  ;; Custo de energia para o modo turbo
        ] [
          fd 0.3  ;; Velocidade reduzida ao passar por dunas
          set energia energia - 4
        ]
      ] [
        ;; Movimentação normal em terreno não-duna
        ifelse turbo-mode-active [
          ;; Limpar área 4x4 quando turbo está ativo
          limpar-area-4x4
          set energia energia - 2  ;; Custo de energia para o modo turbo
        ] [
          fd 1
          set energia energia - 1
        ]
      ]

      ;; Se não está em uma duna, mover normalmente
      if not [duna?] of patch-here [
        ifelse turbo-mode-active [
          limpar-area-4x4  ;; Limpar área 4x4 quando turbo está ativo
          set energia energia - 2  ;; Custo de energia para o modo turbo
        ] [
          ;; Limpar resíduos se estiver num patch com resíduo
          if [residuo?] of patch-here [
            set pcolor orange + 4
            set residuo? false
            set num-residuos num-residuos + 1
          ]
        ]
      ]
    ]
  ]
end

to limpar-area-4x4
  ;; Limpar resíduos em um quadrado 4x4 ao redor do cleaner
  let current-patch patch-here
  let xcor-start [pxcor] of current-patch - 2
  let ycor-start [pycor] of current-patch - 2

  ;; Iterar sobre os patches em um quadrado 4x4
  ask patches with [pxcor >= xcor-start and pxcor <= xcor-start + 3 and pycor >= ycor-start and pycor <= ycor-start + 3] [
    if residuo? [
      set pcolor orange + 4
      set residuo? false
      ;; Aumentar o contador de resíduos limpos
      ask myself [
        set num-residuos num-residuos + 1  ;; Mudado para referir a variável correta
      ]
    ]
  ]
end

to mover-para-posto-carregamento
  ask cleaners [
    ;; Verificar se o patch de carregamento foi definido corretamente
    if posto-carregamento-patch != nobody [
      face posto-carregamento-patch
      fd 1
      if patch-here = posto-carregamento-patch [
        set energia slider-energia  ;; Recarregar energia total
        set tempo-em-recarga 10  ;; Simular tempo de recarga
        set turbo-mode-active false  ;; Desativar o modo turbo ao recarregar
        set total-reparacoes total-reparacoes + 1  ;; Incrementar o contador de reparações
      ]
    ]
  ]
end

to mover-polluters
  ask polluters [
    rt random 360  ;; Rotaciona o polluter em uma direção aleatória

    ;; Verificar se há água ou obstáculo à frente e desviar
    if [agua?] of patch-ahead 1 or [obstaculo?] of patch-ahead 1 [
      rt random 180  ;; Se houver água ou obstáculo, muda de direção
    ]

    ;; Movimentação normal se não houver obstáculos nem água
    if not [agua?] of patch-ahead 1 and not [obstaculo?] of patch-ahead 1 [
      fd 0.6  ;; Move para frente a uma velocidade de 0.6
    ]

    ;; Depósito de resíduos se estiver num patch válido
    if not [agua?] of patch-here and not [residuo?] of patch-here [
      ;; Checar probabilidade e depositar resíduo
      if random-float 1 < probabilidade-deposito [
        ask patch-here [
          set residuo? true
          set pcolor one-of [yellow orange brown]  ;; Definir a cor do resíduo
        ]
      ]
    ]
  ]
end

to limpar-area-4x4-tartarugas
  ;; Limpar resíduos em um quadrado 4x4 ao redor da tartaruga
  let current-patch patch-here
  let xcor-start [pxcor] of current-patch - 2
  let ycor-start [pycor] of current-patch - 2

  ;; Iterar sobre os patches em um quadrado 4x4
  ask patches with [pxcor >= xcor-start and pxcor <= xcor-start + 3 and pycor >= ycor-start and pycor <= ycor-start + 3] [
    if residuo? [
      set pcolor orange + 4
      set residuo? false
      set total-lixo-consumido total-lixo-consumido + 1  ;; Adicione esta linha

      ;; Aumentar o contador de resíduos limpos
      ask myself [
        set num-residuos num-residuos + 1  ;; Mudado para referir a variável correta
      ]
    ]
  ]
end

to mover-crabs
  ask crabs [
    rt random 360
    fd 0.5  ;; Crabs move slowly

    ;; Check for nearby cleaners and attack
    let cleaner-perto one-of cleaners in-radius 2  ;; Check for cleaners within a radius of 2 patches
    if cleaner-perto != nobody [
      face cleaner-perto
      fd 0.5
      ask cleaner-perto [
        set energia energia - 10  ;; Reduz a energia do cleaner ao ser atacado
        set ataque-contador ataque-contador + 1  ;; Atualiza o contador de ataques no crab
      ]
      ;; Aumentar o contador global de ataques
      set total-ataques total-ataques + 1
    ]
  ]
end

to mover-tartarugas
  ask water-turtles [  ;; Atualizado para o novo nome da breed
    ;; Movimento aleatório
    rt random 360
    fd 0.5  ;; Tartarugas se movem lentamente

    ;; Limpar resíduos ao redor
    limpar-area-4x4-tartarugas

    ;; Reduzir energia e verificar se a tartaruga deve morrer
    set energia energia - 1
    if energia <= 0 [
      die  ;; A tartaruga morre se a energia chegar a zero
    ]
  ]
end

to setup-depositos
  let num-depositos slider-num-depositos
  if num-depositos > 0 [
    ask n-of num-depositos patches with [agua? = false] [
      set pcolor blue
      set cor-residuo blue

      sprout 1 [
        set shape "garbage can"
        set size 2
        set color blue
      ]
    ]
  ]
end

to setup-obstaculos
  let num-obstaculos slider-num-obstaculos
  if num-obstaculos > 0 [
    ask n-of num-obstaculos patches with [agua? = false] [
      set obstaculo? true
      sprout 1 [
        set shape "umbrella"
        set size 4
        set color random color
      ]
    ]
  ]
end

to setup-dunas
  let num-dunas slider-num-dunas
  if num-dunas > 0 [
    ;; Criar dunas como quadrados 2x2
    ask n-of num-dunas patches with [agua? = false and pxcor < max-pxcor and pycor < max-pycor] [
      ;; Definir o patch atual e os três patches adjacentes para formar uma duna 2x2
      set duna? true
      set pcolor brown + 2

      ask patch-at 1 0 [  ;; Patch à direita
        set duna? true
        set pcolor brown + 2
      ]
      ask patch-at 0 1 [  ;; Patch acima
        set duna? true
        set pcolor brown + 2
      ]
      ask patch-at 1 1 [  ;; Patch diagonal superior-direita
        set duna? true
        set pcolor brown + 2
      ]
    ]
  ]
end

to setup-postos-carregamento
  ;; Criar uma turtle para representar o posto de carregamento
  create-turtles 1 [
    set color green - 1  ;; Definir a cor da turtle para um verde escuro
    set shape "posto"    ;; Definir a forma como "posto"
    set size 3
    setxy min-pxcor min-pycor  ;; Posicionar a turtle no canto inferior esquerdo
  ]

  ;; Agora pedir à turtle para obter a referência do patch
  let patch-posto-carregamento patch min-pxcor min-pycor  ;; Obter o patch onde a turtle está localizada
  ask patch-posto-carregamento [
    set posto-carregamento? true  ;; Marcar o patch como um posto de carregamento
  ]

  ;; Salvar a referência do patch na variável global
  set posto-carregamento-patch patch-posto-carregamento
end

to aparecer-tartarugas
  ;; Aumenta o timer a cada tick e cria tartarugas em intervalos
  set tartaruga-timer tartaruga-timer + 1
  if tartaruga-timer >= 30 [  ;; Intervalo para aparecer a tartaruga (ex: 30 ticks)
    create-water-turtles 1 [  ;; Atualizado para o novo nome da breed
      setxy random-xcor random-ycor
      set color turquoise
      set shape "turtle"
      set size 2
      set energia 20  ;; Energia inicial da tartaruga
      set tempo-de-vida 50  ;; Tempo de vida inicial
      set num-residuos 0  ;; Inicializa o contador de resíduos
    ]
    set tartaruga-timer 0  ;; Reinicia o timer
  ]
end

to go
  mover-cleaner
  mover-polluters
  mover-crabs  ;; Movimentar os caranguejos
  mover-tartarugas  ;; Movimentar as tartarugas
  aparecer-tartarugas  ;; Criar tartarugas em intervalos
  set-current-plot "Lixo Consumido por Tartarugas"
  set-current-plot-pen "Lixo"
plot total-lixo-consumido

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
59
89
122
122
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
61
142
124
175
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
53
192
132
225
Go_Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
209
521
272
554
Go_N
repeat slider-ticks [ mover-cleaner mover-polluters tick ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
707
57
935
88
Controlos do Cleaner:
16
0.0
1

TEXTBOX
918
57
1092
81
Controlos dos Polluters:
16
0.0
1

SLIDER
696
98
868
131
slider-energia
slider-energia
0
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
696
151
868
184
slider-limite-residuos
slider-limite-residuos
1
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
915
96
1121
129
slider-probabilidade-polluter1
slider-probabilidade-polluter1
0
1
0.26
0.01
1
NIL
HORIZONTAL

SLIDER
916
150
1122
183
slider-probabilidade-polluter2
slider-probabilidade-polluter2
0
1
0.4
0.01
1
NIL
HORIZONTAL

SLIDER
916
199
1122
232
slider-probabilidade-polluter3
slider-probabilidade-polluter3
0
1
0.42
0.01
1
NIL
HORIZONTAL

SLIDER
296
521
468
554
slider-ticks
slider-ticks
1
100
100.0
1
1
NIL
HORIZONTAL

MONITOR
701
337
888
382
Energia atual do Cleaner
[energia] of one-of cleaners
17
1
11

MONITOR
701
398
888
443
Resíduos Coletados
[num-residuos] of one-of cleaners
17
1
11

MONITOR
701
458
887
503
Resíduos depositados no Ambiente
count patches with [residuo? = true]
17
1
11

TEXTBOX
65
58
215
78
Botões:
16
0.0
1

PLOT
1192
86
1394
242
Evolução da Poluição
Ticks (tempo)
Nº de patches com resíduos
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Poluição" 1.0 0 -7500403 true "" "plot count patches with [residuo? = true]"

PLOT
1191
249
1395
407
Limpeza pelo Cleaner
Ticks (tempo)
Nº de patches limpos
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Limpeza" 1.0 0 -16777216 true "" "plot sum [num-residuos] of cleaners"

TEXTBOX
209
480
428
515
Os agentes circulam n ticks:
16
0.0
1

TEXTBOX
1175
56
1325
76
Gráficos:
16
0.0
1

TEXTBOX
706
300
856
320
Informações:
16
0.0
1

SLIDER
696
249
868
282
slider-num-depositos
slider-num-depositos
2
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
696
198
868
231
slider-tempo-carregamento
slider-tempo-carregamento
1
10
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
708
16
1103
60
Ajuda o aspirador a mantêr a praia limpa:
20
0.0
1

SLIDER
916
250
1122
283
slider-num-obstaculos
slider-num-obstaculos
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
914
338
1119
371
slider-numero-ataques
slider-numero-ataques
1
10
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
918
312
1068
332
Features novas:
16
0.0
1

SLIDER
914
377
1120
410
slider-numero-crabs
slider-numero-crabs
0
10
1.0
1
1
NIL
HORIZONTAL

MONITOR
701
510
887
555
Nº de Ataques ao Cleaner
total-ataques
17
1
11

MONITOR
700
562
888
607
Nº de Reparações Efetuadas
total-reparacoes
17
1
11

SLIDER
915
421
1120
454
slider-num-dunas
slider-num-dunas
0
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
914
465
1120
498
slider-numero-cleaners
slider-numero-cleaners
1
10
1.0
1
1
NIL
HORIZONTAL

SWITCH
500
521
650
554
switch-turbo
switch-turbo
1
1
-1000

TEXTBOX
500
479
693
497
Modo Turbo (ON/OFF):
16
0.0
1

PLOT
1193
419
1393
569
Lixo Consumido por Tartarugas
Lixo Consumido
Ticks (tempo)
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Lixo" 1.0 0 -16777216 true "" "plot total-lixo-consumido"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

crab
true
0
Rectangle -955883 true false 105 135 195 165
Polygon -955883 true false 105 165 90 180 120 180 105 165
Polygon -955883 true false 195 165 180 180 210 180 195 165
Polygon -955883 true false 105 135 90 150 105 165
Polygon -955883 true false 195 135 210 150 195 165
Polygon -955883 true false 120 135 135 120 150 135
Polygon -955883 true false 165 135
Polygon -955883 true false 150 135 165 120 180 135
Line -955883 false 210 150 225 135
Line -955883 false 90 150 75 135
Circle -955883 true false 60 105 30
Circle -955883 true false 210 105 30
Polygon -955883 true false 60 105 60 105 75 90 90 105 90 120 60 120 60 105
Polygon -955883 true false 210 105 210 120 240 120 240 105 225 90 210 105
Line -6459832 false 225 90 225 90
Line -6459832 false 225 90 225 90
Line -6459832 false 225 90 225 120
Line -6459832 false 75 90 75 120

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

garbage can
false
0
Polygon -16777216 false false 60 240 66 257 90 285 134 299 164 299 209 284 234 259 240 240
Rectangle -7500403 true true 60 75 240 240
Polygon -7500403 true true 60 238 66 256 90 283 135 298 165 298 210 283 235 256 240 238
Polygon -7500403 true true 60 75 66 57 90 30 135 15 165 15 210 30 235 57 240 75
Polygon -7500403 true true 60 75 66 93 90 120 135 135 165 135 210 120 235 93 240 75
Polygon -16777216 false false 59 75 66 57 89 30 134 15 164 15 209 30 234 56 239 75 235 91 209 120 164 135 134 135 89 120 64 90
Line -16777216 false 210 120 210 285
Line -16777216 false 90 120 90 285
Line -16777216 false 125 131 125 296
Line -16777216 false 65 93 65 258
Line -16777216 false 175 131 175 296
Line -16777216 false 235 93 235 258
Polygon -16777216 false false 112 52 112 66 127 51 162 64 170 87 185 85 192 71 180 54 155 39 127 36

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

posto
false
0
Rectangle -5825686 true false 60 75 150 225
Rectangle -16777216 false false 75 90 135 210
Line -16777216 false 120 105 90 135
Line -16777216 false 90 135 120 165
Line -16777216 false 120 165 90 195
Line -5825686 false 105 195 120 195
Circle -5825686 true false 135 150 30
Line -5825686 false 165 165 180 135
Line -5825686 false 150 165 165 135
Polygon -5825686 false false 165 135 195 135 195 120 165 120 165 135 150 135

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

ufo top
false
0
Circle -1 true false 15 15 270
Circle -16777216 false false 15 15 270
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -7500403 true true 60 60 30
Circle -7500403 true true 135 30 30
Circle -7500403 true true 210 60 30
Circle -7500403 true true 240 135 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 135 240 30
Circle -7500403 true true 60 210 30
Circle -7500403 true true 30 135 30
Circle -16777216 false false 30 135 30
Circle -16777216 false false 60 210 30
Circle -16777216 false false 135 240 30
Circle -16777216 false false 210 210 30
Circle -16777216 false false 240 135 30
Circle -16777216 false false 210 60 30
Circle -16777216 false false 135 30 30
Circle -16777216 false false 60 60 30

umbrella
false
0
Rectangle -7500403 true true 45 135 195 195
Line -16777216 false 60 135 60 195
Line -16777216 false 180 135 180 195
Line -1 false 210 195 210 90
Polygon -7500403 true true 210 90 150 90 165 75 210 45 255 75 270 90 210 90
Line -16777216 false 90 165 75 150
Line -16777216 false 75 180 90 165
Line -16777216 false 90 165 135 165
Line -16777216 false 120 165 105 180
Line -16777216 false 120 165 105 150
Circle -16777216 true false 135 150 30

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
