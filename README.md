# sketchybar-codexbar-theme

A compact SketchyBar theme with a built-in CodexBar usage item, tuned for a clean top bar layout and day-to-day development use.

This theme was originally based on an existing SketchyBar theme and then modified to fit my own workflow and preferences.

## Preview

![Theme preview](assets/preview.png)

The CodexBar item refreshes every 5 minutes and only shows providers that currently return usable data. Providers that are disabled or unavailable are hidden automatically.

## Features

- Compact laptop and desktop variants
- Front app indicator
- Current space item
- Clock
- Weather
- Volume
- Battery on laptop
- CodexBar usage item with automatic provider filtering

## CodexBar item

The CodexBar item reads:

```sh
codexbar usage --format json
```

It then:

- shows only providers with valid usage data
- ignores provider error entries
- tolerates partial provider failures
- hides itself when no usable providers are returned

Current label format:

```text
CDX 97% · GEM 100% · COP 59%
```

Values represent remaining quota for each provider.

## Requirements

- macOS
- `sketchybar`
- `jq`
- `yabai`
- `codexbar` for the usage item
- a Nerd Font for the icons

## Installation

Clone the repo into your SketchyBar config location:

```sh
git clone git@github.com:1mpossible-code/sketchybar-codexbar-theme.git ~/.config/sketchybar
```

Then reload SketchyBar:

```sh
sketchybar --reload
```

If your setup differs, copy the files into your existing SketchyBar config and merge the items you want.

## File layout

- `sketchybarrc` selects laptop or desktop mode
- `sketchybarrc-laptop` contains the laptop bar layout
- `sketchybarrc-desktop` contains the desktop bar layout
- `plugins/` contains shared plugins
- `plugins-laptop/` contains laptop-specific plugins

## Attribution

This project is a modified theme, not a from-scratch design. If you know the original source theme, replace this note with a direct credit link.
