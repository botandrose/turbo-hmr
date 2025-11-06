# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

turbo-hmr is a Ruby gem that provides Hot Module Replacement (HMR) for Turbo with Importmap. It detects when pinned Stimulus controller modules change across Turbo-driven navigations and attempts to hot-swap them without triggering a full page reload.

## Architecture

The gem has two main components that work together:

**Ruby/Rails side:**
- `lib/turbo/hmr/engine.rb` - Rails Engine that sets up asset paths and registers helpers
- `lib/turbo/hmr/importmap_helper.rb` - Overrides the default `javascript_inline_importmap_tag` to remove `data-turbo-track="reload"` attribute, which is essential for HMR to intercept importmap changes
- `lib/generators/turbo/hmr/install_generator.rb` - Generator that configures the host application

**JavaScript side:**
- `app/javascript/turbo-hmr.js` - Core HMR logic that:
  - Listens to `turbo:before-fetch-response` to extract the incoming page's importmap
  - Compares importmaps in `turbo:before-render` to detect changes
  - Hot-swaps changed Stimulus controllers by calling `application.unload()` and `application.register()` with re-imported modules
  - Falls back to full reload via `Turbo.visit()` if non-controller imports change or hot-swap fails
  - Only hot-swaps modules matching `controllers/*` pattern (configurable via `isControllerImport()`)

**Key flow:**
1. Importmap helper removes `data-turbo-track` attribute to prevent automatic reloads
2. JavaScript intercepts Turbo navigation events to compare old vs new importmaps
3. If only controllers changed: hot-swap them without page reload
4. If anything else changed: trigger full reload

## Development Commands

**Run tests:**
```bash
bundle exec rspec
```

**Run specific test:**
```bash
bundle exec rspec spec/system/hotswap_system_spec.rb
```

**Run single focused test:**
```bash
bundle exec rspec spec/system/hotswap_system_spec.rb:<line_number>
```

## Testing

The gem uses RSpec with system tests powered by Capybara and Cuprite (headless Chrome driver). The test suite includes a dummy Rails app in `spec/dummy/` that simulates a real Rails application with Turbo and Stimulus.

System tests verify HMR behavior by:
- Modifying controller files at runtime (`write_version_controller`)
- Navigating between pages with Turbo
- Verifying controllers hot-swap without full page reloads
- Checking page load counts using custom `have_been_loaded` matcher

The dummy app is essential for testing - it's not just scaffolding but a functioning Rails app that exercises the actual HMR flow.

## Important Constraints

- Hot-swapping only works for Stimulus controllers (modules under `controllers/` in importmap)
- Controllers must be safe to re-import (no problematic side-effects during module evaluation)
- Requires importmap entries to include cache-busting digests (Rails default in development/test)
- The `data-turbo-track="reload"` attribute MUST be removed from importmap script tags
