#!/bin/bash

# touch /var/www/html/EdfTempo/tempo.html
# chmod +x /var/www/html/EdfTempo/tempo.sh
# /bin/bash /var/www/html/EdfTempo/tempo.sh
# 0 */2       *   *   *   /bin/bash /var/www/html/EdfTempo/tempo.sh

# Output HTML file path
output_file="/var/www/html/EdfTempo/tempo.html"

declare -A bgcolors=(
  ["Bleu"]="#228be6"
  ["Rouge"]="#fa5252"
  ["Blanc"]="#adb5bd"
  # Map some known libTarif prefixes to colors for the now API
  ["Bleu-HP"]="#228be6"
  ["Bleu-HC"]="#228be6"
  ["Rouge-HP"]="#fa5252"
  ["Rouge-HC"]="#fa5252"
  ["Blanc-HP"]="#adb5bd"
  ["Blanc-HC"]="#adb5bd"
)

extract_json_field() {
  echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed -E "s/\"$2\"[[:space:]]*:[[:space:]]*\"([^\"]*)\"/\1/"
}

extract_json_number() {
  echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*[0-9\.]*" | head -1 | sed -E "s/\"$2\"[[:space:]]*:[[:space:]]*([0-9\.]*)/\1/"
}

fetch_tempo() {
  local endpoint=$1
  local json=$(curl -s "$endpoint")

  local dateJour=$(extract_json_field "$json" "dateJour")
  local libCouleur=$(extract_json_field "$json" "libCouleur")

  local fdate=$(LC_TIME=fr_FR.UTF-8 date -d "$dateJour" "+%A %d %B %Y")
  fdate="$(tr '[:lower:]' '[:upper:]' <<< ${fdate:0:1})${fdate:1}"

  echo "<div class='tempo' style='background-color: ${bgcolors[$libCouleur]:-#333};'>$fdate</div>"
}

fetch_now() {
  local endpoint=$1
  local json=$(curl -s "$endpoint")

  local libTarif=$(extract_json_field "$json" "libTarif")
  local tarifKwh=$(extract_json_number "$json" "tarifKwh")
  local color=${bgcolors[$libTarif]:-#555}

  echo "<div class='tempo' style='background-color: $color;'>"
  echo "$libTarif à $tarifKwh €/kWh"
  echo "</div>"
}

cat > "$output_file" <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <title>Couleur Tempo</title>
  <style>
    body {
      font-family: sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      margin: 2em;
    }
    .edf-header {
      display: flex;
      align-items: center;
      gap: 1em;
      font-size: 1.3em;
      font-weight: bold;
      margin-bottom: 0.2em;
      width: 210px;
    }
    .tempo {
      color: white;
      font-size: 1em;
      font-weight: bold;
      padding: 1em 1em;
      border-radius: 0.5em;
      width: 210px;
      box-shadow: 0 4px 16px rgba(0,0,0,0.1);
      text-align: center;
      margin: 0.5em 0;
    }

  </style>
</head>
<body>
<div class="edf-header">
  <img src="https://www.edf.fr/themes/custom/nova/assets/images/00-tokens/logos/images/logo-edf.svg"
    alt="EDF logo" height="48" style="background:white;border-radius:12px;padding:4px;">
  <span>Tempo</span>
</div>
EOF

# Append the current tariff div
echo "$(fetch_now 'https://www.api-couleur-tempo.fr/api/now')" >> "$output_file"

# Append today and tomorrow divs
echo "$(fetch_tempo 'https://www.api-couleur-tempo.fr/api/jourTempo/today')" >> "$output_file"
echo "$(fetch_tempo 'https://www.api-couleur-tempo.fr/api/jourTempo/tomorrow')" >> "$output_file"


echo "</body></html>" >> "$output_file"
