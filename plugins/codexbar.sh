#!/usr/bin/env zsh

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

MANAGER_NAME="codexbar"
SCRIPT_PATH="${0:A}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar"
MODE_FILE="$STATE_DIR/codexbar_mode"

DEFAULT_COLOR="0xffcad3f5"
GREEN="0xffa6da95"
YELLOW="0xffeed49f"
RED="0xffed8796"
INTENSE_RED="0xffff5c7c"
BLUE="0xff8aadf4"
BACKGROUND="0xff24273a"

short_provider_name() {
    case "$1" in
    codex) echo "CDX" ;;
    cursor) echo "CUR" ;;
    gemini) echo "GEM" ;;
    copilot) echo "COP" ;;
    claude) echo "CLD" ;;
    openai) echo "OAI" ;;
    *)
        local normalized="${1//-/}"
        echo "${(U)normalized[1,3]}"
        ;;
    esac
}

provider_item_name() {
    local safe_name
    safe_name="$(printf '%s' "$1" | tr -c '[:alnum:]_' '_')"
    echo "$MANAGER_NAME.$safe_name"
}

current_mode() {
    [[ -f "$MODE_FILE" ]] && cat "$MODE_FILE" || echo "split"
}

toggle_mode() {
    mkdir -p "$STATE_DIR"
    if [[ "$(current_mode)" == "split" ]]; then
        echo "compact" > "$MODE_FILE"
    else
        echo "split" > "$MODE_FILE"
    fi
}

reset_color() {
    local resets_at="$1"
    local window_minutes="$2"
    [[ -z "$resets_at" || -z "$window_minutes" ]] && echo "$DEFAULT_COLOR" && return

    local reset_epoch now_epoch minutes_left
    reset_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$resets_at" "+%s" 2>/dev/null)"
    [[ -z "$reset_epoch" ]] && echo "$DEFAULT_COLOR" && return

    now_epoch="$(date -u "+%s")"
    minutes_left=$(((reset_epoch - now_epoch) / 60))

    if (( minutes_left <= 30 )); then
        echo "$INTENSE_RED"
    elif (( minutes_left <= 60 )); then
        echo "$RED"
    elif (( minutes_left <= window_minutes / 2 )); then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

remove_stale_items() {
    local desired_items="$1"
    local existing item

    existing="$(sketchybar --query bar | jq -r '.items[] | select(startswith("'"$MANAGER_NAME"'."))')"
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if ! printf '%s\n' "$desired_items" | grep -qx "$item"; then
            sketchybar --remove "$item" >/dev/null 2>&1
        fi
    done <<< "$existing"
}

format_remaining() {
    local used="$1"
    used="${used%%.*}"
    (( used < 0 )) && used=0
    (( used > 100 )) && used=100
    echo $((100 - used))
}

update_provider_item() {
    local item="$1" provider="$2" used="$3" color="$4" position="$5"
    local remaining short_name

    remaining="$(format_remaining "$used")"
    short_name="$(short_provider_name "$provider")"

    sketchybar --query "$item" >/dev/null 2>&1 || sketchybar --add item "$item" "$position"
    sketchybar --set "$item" \
        script="$SCRIPT_PATH" \
        icon="$short_name" \
        icon.color="$DEFAULT_COLOR" \
        icon.padding_right=4 \
        label="${remaining}%" \
        label.color="$color" \
        label.padding_left=0 \
        label.padding_right=6 \
        background.color="$BACKGROUND" \
        drawing=on \
        --subscribe "$item" mouse.clicked
}

show_compact_item() {
    local usage_json="$1"
    local segments=()
    local provider used remaining

    remove_stale_items ""
    while IFS=$'\t' read -r provider used; do
        [[ -z "$provider" ]] && continue
        remaining="$(format_remaining "$used")"
        segments+=("$(short_provider_name "$provider") ${remaining}%")
    done < <(provider_rows "$usage_json" | cut -f1-2)

    if (( ${#segments[@]} == 0 )); then
        sketchybar --set "$MANAGER_NAME" drawing=off
        return
    fi

    sketchybar --set "$MANAGER_NAME" \
        drawing=on \
        icon= \
        icon.color="$BLUE" \
        label="${(j: · :)segments}" \
        label.color="$DEFAULT_COLOR" \
        background.color="$BACKGROUND"
}

provider_rows() {
    printf '%s' "$1" | jq -r '.[] | select(.provider != null and .error == null and .usage.primary != null) | [.provider, ((.usage.primary.usedPercent // 0) | round), (.usage.primary.resetsAt // ""), (.usage.primary.windowMinutes // "")] | @tsv'
}

show_split_items() {
    local usage_json="$1"
    local position="$2"
    local desired_items=""
    local provider used resets_at window_minutes item color

    sketchybar --set "$MANAGER_NAME" drawing=off
    while IFS=$'\t' read -r provider used resets_at window_minutes; do
        [[ -z "$provider" ]] && continue
        item="$(provider_item_name "$provider")"
        color="$(reset_color "$resets_at" "$window_minutes")"
        desired_items+="$item"$'\n'
        update_provider_item "$item" "$provider" "$used" "$color" "$position"
    done < <(provider_rows "$usage_json")

    remove_stale_items "$desired_items"
}

update_usage() {
    if ! command -v codexbar >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        sketchybar --set "$MANAGER_NAME" drawing=off
        return
    fi

    [[ "$SENDER" == "mouse.clicked" ]] && toggle_mode

    local position usage_json
    position="$(sketchybar --query "$MANAGER_NAME" | jq -r '.geometry.position // "right"')"
    usage_json="$(codexbar usage --format json 2>/dev/null)"

    if [[ -z "$usage_json" ]] || ! printf '%s' "$usage_json" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
        sketchybar --set "$MANAGER_NAME" drawing=off
        remove_stale_items ""
        return
    fi

    if [[ "$(current_mode)" == "compact" ]]; then
        show_compact_item "$usage_json"
    else
        show_split_items "$usage_json" "$position"
    fi
}

update_usage
