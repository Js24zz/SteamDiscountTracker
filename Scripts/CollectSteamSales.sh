#!/bin/bash

BASE_URL="https://store.steampowered.com/api/appdetails"
DATA_DIR="Data"
LOG_DIR="Logs"
LOG_FILE="${LOG_DIR}/collect.log"

mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

appids=("413150" "1145360" "1091500" "1245620" "620" "105600" "367520" "1174180" "292030" "814380")
names=("Stardew Valley" "Hades" "Cyberpunk 2077" "ELDEN RING" "Portal 2" "Terraria" "Hollow Knight" "Red Dead Redemption 2" "The Witcher 3: Wild Hunt" "Sekiro: Shadows Die Twice")


for index in "${!appids[@]}"; do
    appid="${appids[$index]}"
    name="${names[$index]}"
    now="$(date '+%Y-%m-%d %H:%M:%S')"
    url="${BASE_URL}?appids=${appid}&cc=my&l=en&filters=price_overview"

    json=$(curl -s "$url")
    curl_status=$?

    if [ $curl_status -ne 0 ] || [ -z "$json" ]; then
        echo "$now | ERROR | curl failed for appid $appid" >> "$LOG_FILE"
        continue
    fi

    success=$(echo "$json" | grep -o '"success":[^,]*' | head -n1 | cut -d':' -f2)

    if [ "$success" != "true" ]; then
        echo "$now | ERROR | success flag not true for appid $appid" >> "$LOG_FILE"
        continue
    fi

    currency=$(echo "$json" | grep -o '"currency":"[^"]*' | head -n1 | cut -d'"' -f4)
    initial=$(echo "$json" | grep -o '"initial":[0-9]*' | head -n1 | sed 's/[^0-9]//g')
    final=$(echo "$json" | grep -o '"final":[0-9]*' | head -n1 | sed 's/[^0-9]//g')
    discount=$(echo "$json" | grep -o '"discount_percent":[0-9]*' | head -n1 | sed 's/[^0-9]//g')

    if [ -z "$currency" ] || [ -z "$initial" ] || [ -z "$final" ] || [ -z "$discount" ]; then
        echo "$now | ERROR | missing fields for appid $appid" >> "$LOG_FILE"
        continue
    fi

    safe_name=$(printf "%s" "$name" | sed "s/'/''/g")
    timestamp="$(date '+%Y%m%d%H%M%S')"
    echo "$json" > "${DATA_DIR}/${appid}_${timestamp}.json"

    sudo mysql -D steam_sale_tracker <<EOF 2>>"$LOG_FILE"
INSERT INTO games (appid, name)
VALUES (${appid}, '${safe_name}')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO price_history (game_id, checked_at, currency, initial_price, final_price, discount_percent)
SELECT game_id, '${now}', '${currency}', ${initial}, ${final}, ${discount}
FROM games WHERE appid = ${appid};
EOF

    if [ $? -ne 0 ]; then
        echo "$now | ERROR | MySQL insert failed for appid $appid" >> "$LOG_FILE"
    else
        echo "$now | INFO  | Stored price for appid $appid" >> "$LOG_FILE"
    fi
done
