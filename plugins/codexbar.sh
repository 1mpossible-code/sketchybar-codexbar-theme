#!/usr/bin/env zsh

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

DEFAULT_COLOR="0xffcad3f5"
GREEN="0xffa6da95"
YELLOW="0xffeed49f"
RED="0xffed8796"
INTENSE_RED="0xffff5c7c"

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
    echo "codexbar.$safe_name"
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

    existing="$(sketchybar --query bar | jq -r '.items[] | select(startswith("codexbar."))')"
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if ! printf '%s\n' "$desired_items" | grep -qx "$item"; then
            sketchybar --remove "$item" >/dev/null 2>&1
        fi
    done <<< "$existing"
}

update_provider_item() {
    local item="$1" provider="$2" used="$3" color="$4" position="$5"
    local remaining short_name

    used="${used%%.*}"
    (( used < 0 )) && used=0
    (( used > 100 )) && used=100
    remaining=$((100 - used))
    short_name="$(short_provider_name "$provider")"

    sketchybar --query "$item" >/dev/null 2>&1 || sketchybar --add item "$item" "$position"
    sketchybar --set "$item" \
        icon="$short_name" \
        icon.color="$DEFAULT_COLOR" \
        icon.padding_right=4 \
        label="${remaining}%" \
        label.color="$color" \
        label.padding_left=0 \
        label.padding_right=6 \
        background.color=0xff24273a \
        drawing=on
}

update_usage() {
    if ! command -v codexbar >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        sketchybar --set "$NAME" drawing=off
        return
    fi

    local position usage_json desired_items row provider used resets_at window_minutes item color
    position="$(sketchybar --query "$NAME" | jq -r '.geometry.position // "right"')"
    usage_json="$(codexbar usage --format json 2>/dev/null)"
    sketchybar --set "$NAME" drawing=off

    if [[ -z "$usage_json" ]] || ! printf '%s' "$usage_json" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
        remove_stale_items ""
        return
    fi

    desired_items=""
    while IFS=$'\t' read -r provider used resets_at window_minutes; do
        [[ -z "$provider" ]] && continue
        item="$(provider_item_name "$provider")"
        color="$(reset_color "$resets_at" "$window_minutes")"
        desired_items+="$item"$'\n'
        update_provider_item "$item" "$provider" "$used" "$color" "$position"
    done < <(printf '%s' "$usage_json" | jq -r '.[] | select(.provider != null and .error == null and .usage.primary != null) | [.provider, ((.usage.primary.usedPercent // 0) | round), (.usage.primary.resetsAt // ""), (.usage.primary.windowMinutes // "")] | @tsv')

    remove_stale_items "$desired_items"
}

update_usage
