class_name RuleStage
extends Resource
## Una etapa de un objetivo escalonado (S-03): umbral de progreso, premio y mensaje.
## Sirve para cualquier cadena de "etapas con premio creciente" (las vueltas de Carfax, el jackpot
## de profundidad, y las misiones de Baker Street o Alicia) sin tocar código: se arma una lista
## `Array[RuleStage]` en el TableRules y la pieza avanza por ella. No es un motor de misiones: cada
## pieza decide cuándo avanza; la etapa solo guarda los números y el texto.

## Progreso necesario para estar en esta etapa (metros, vueltas, golpes...). Lo usa `TableRules.stage_index_for`;
## si la pieza avanza por orden (Carfax) puede quedar en 0.
@export var threshold := 0
## Puntos que paga la etapa al cumplirse.
@export var award := 0
## Si la etapa, al cumplirse, sube el multiplicador del bonus.
@export var raise_multiplier := false
## Mensaje para `GameState.say`. Admite {bonus} {stage} {total} {award} {depth}; vacío = no dice nada.
@export var message := ""
