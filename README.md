# turbo-hmr

Hot Module Replacement for Turbo with Importmap.

This gem detects when pinned Stimulus controller modules change across a Turbo-driven navigation (e.g., `Turbo.visit`). If the new page’s importmap updates any Stimulus controllers, the gem attempts to swap in the updated controllers without a full page reload by:

- Disconnecting existing controller instances for the changed identifiers
- Re-importing the updated modules
- Re-registering/reconnecting controllers so instances start using the new code
- Preventing the full page reload

If any changed importmap item can’t be safely hot-swapped, we fall back upon the default Turbo.visit behavior to ensure correctness.

## Why

More seamless deployments for long-lived single-page sessions.

Turbo’s morphing normally keeps you on the page without a full reload, but the browser doesn’t automatically re-import modules whose specifiers are unchanged while their URLs in the importmap have changed, and instead just does a full page load. This gem bridges that gap by watching for importmap diffs and applying a targeted hot swap.

## How It Works

This gem disables Turbo's built-in `data-turbo-track="reload"` behavior for importmaps and replaces it with smarter logic:

1. During Turbo navigations, it intercepts `turbo:before-fetch-response` to extract the incoming page's importmap
2. In `turbo:before-render`, it compares importmaps and detects what changed
3. If only Stimulus controllers changed, it hot-swaps them without a full page reload
4. Controllers are hot-swapped by calling `Stimulus.unload()` and `Stimulus.register()` with the new module
5. If any non-controller imports changed, it triggers a full reload via `Turbo.visit()`

**Caveat emptor: This process assumes that all stimulus controllers can be safely unloaded and reloaded without problematic side-effects. Users of this gem need to ensure that their controllers are safe to re-import!**

## Installation

1. Add to your Gemfile:

   ```ruby
   gem "turbo-hmr"
   ```

2. Run the installer:

   ```bash
   bin/rails generate turbo:hmr:install
   ```

   This will:
   - Pin the `turbo-hmr` JavaScript module in `config/importmap.rb`
   - Set it up in `app/javascript/application.js`

## Limitations

- Only swaps Stimulus controllers; other module changes will trigger a full page reload.
- Assumes that controllers do not have problematic side-effects during module evaluation. The onus is upon the user of this gem to ensure their controllers are safe to re-import.
- Assumes importmap entries include cache-busting digests when files change (Rails does this by default in development/test).
- Requires disabling `data-turbo-track="reload"` on the importmap script tag (this gem monkeypatches importmaps-rails to do this).

## Roadmap

- Configurable module matching (allow/deny lists)
- Opt-in HMR for non-controller modules

## License

MIT
