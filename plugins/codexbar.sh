#!/usr/bin/env zsh

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

short_provider_name() {
    case "$1" in
    codex)
        echo "CDX"
        ;;
    cursor)
        echo "CUR"
        ;;
    gemini)
        echo "GEM"
        ;;
    copilot)
        echo "COP"
        ;;
    claude)
        echo "CLD"
        ;;
    openai)
        echo "OAI"
        ;;
    *)
        local normalized="${1//-/}"
        echo "${(U)normalized[1,3]}"
        ;;
    esac
}

update_usage() {
    if ! command -v codexbar >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        sketchybar --set "$NAME" drawing=off
        return
    fi

    local usage_json
    usage_json="$(codexbar usage --format json 2>/dev/null)"

    if [[ -z "$usage_json" ]] || ! printf '%s' "$usage_json" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
        sketchybar --set "$NAME" drawing=off
        return
    fi

    local segments=()
    local provider used remaining

    while IFS=$'\t' read -r provider used; do
        [[ -z "$provider" ]] && continue
        used="${used%%.*}"
        (( used < 0 )) && used=0
        (( used > 100 )) && used=100
        remaining=$((100 - used))
        segments+=("$(short_provider_name "$provider") ${remaining}%")
    done < <(printf '%s' "$usage_json" | jq -r '.[] | select(.provider != null and .error == null and .usage.primary != null) | [.provider, ((.usage.primary.usedPercent // 0) | round)] | @tsv')

    if (( ${#segments[@]} == 0 )); then
        sketchybar --set "$NAME" drawing=off
        return
    fi

    sketchybar --set "$NAME" drawing=on label="${(j: · :)segments}" label.drawing=on
}

update_usage
