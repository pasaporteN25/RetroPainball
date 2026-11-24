#!/usr/bin/env bash
# Playtesting con bots (F1a): corre varios procesos de Godot en paralelo y arma el informe.
#
# Uso:  ./tools/playtest.sh [-t mesas] [-b bots] [-n bolas] [-s semilla] [-x velocidad] [-j procesos] [-o carpeta] [-r]
#   -t  mesas separadas por coma, o "all"          (por defecto: kernel_panic)
#   -b  bots: novato,medio,experto,azar o "all"    (por defecto: medio)
#   -n  bolas por combinación mesa/bot             (por defecto: 100)
#   -s  semilla base; cada proceso suma su número  (por defecto: 1)
#   -x  factor entero de velocidad; con 1 ya va ~25x más rápido que tiempo real gracias a
#       --fixed-fps 60, y subirlo casi no suma (ver tools/playtest/README.md)  (por defecto: 1)
#   -j  procesos en paralelo                       (por defecto: la mitad de los núcleos)
#   -o  carpeta de salida                          (por defecto: build/playtest/<fecha-hora>)
#   -r  no generar el informe Markdown al final
# Ejemplo:  ./tools/playtest.sh -t kernel_panic -b medio -n 2000 -j 6
#
# Una combinación se reparte en varios procesos ("shards") si hay más núcleos que combinaciones;
# el informe junta los .jsonl de la misma mesa y bot como una sola muestra.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot="${GODOT:-godot}"
tables="kernel_panic"
bots="medio"
balls=100
seed=1
speed=1
jobs=$(( $(nproc) / 2 ))
[ "$jobs" -lt 1 ] && jobs=1
out=""
report=1

while getopts "t:b:n:s:x:j:o:rh" opt; do
	case "$opt" in
		t) tables="$OPTARG" ;;
		b) bots="$OPTARG" ;;
		n) balls="$OPTARG" ;;
		s) seed="$OPTARG" ;;
		x) speed="$OPTARG" ;;
		j) jobs="$OPTARG" ;;
		o) out="$OPTARG" ;;
		r) report=0 ;;
		*) sed -n '2,17p' "${BASH_SOURCE[0]}"; exit 1 ;;
	esac
done

[ "$tables" = "all" ] && tables="kernel_panic,nautilus,dracula,alicia"
[ "$bots" = "all" ] && bots="novato,medio,experto,azar"
[ -z "$out" ] && out="build/playtest/$(date +%Y-%m-%d_%H%M)"
case "$out" in /*) abs_out="$out" ;; *) abs_out="$root/$out" ;; esac
mkdir -p "$abs_out"

IFS=',' read -ra table_list <<< "$tables"
IFS=',' read -ra bot_list <<< "$bots"
combos=$(( ${#table_list[@]} * ${#bot_list[@]} ))
fps=$(( 60 * ${speed%.*} ))
shards=$(( (jobs + combos - 1) / combos ))
[ "$shards" -lt 1 ] && shards=1
per_shard=$(( (balls + shards - 1) / shards ))

echo "Playtest: ${#table_list[@]} mesa(s) x ${#bot_list[@]} bot(s), $balls bolas c/u en $shards proceso(s), x$speed, $jobs en paralelo"
echo "Salida: $abs_out"

"$godot" --headless --path "$root" --import > /dev/null 2>&1 || true

commands=()
for table in "${table_list[@]}"; do
	for bot in "${bot_list[@]}"; do
		for (( i = 0; i < shards; i++ )); do
			commands+=("$godot --headless --fixed-fps $fps --path $root -s tools/playtest/run.gd -- table=$table bot=$bot balls=$per_shard seed=$(( seed + i )) speed=$speed out=$abs_out tag=_s$i")
		done
	done
done

printf '%s\n' "${commands[@]}" | xargs -P "$jobs" -I{} bash -c '{} 2>&1 | grep -E "^(kernel_panic|nautilus|dracula|alicia)/|SCRIPT ERROR|Parse Error" || true'

if [ "$report" -eq 1 ]; then
	"$godot" --headless --path "$root" -s tools/playtest/report.gd -- "dir=$abs_out" "out=docs/playtest/$(basename "$abs_out").md"
fi
