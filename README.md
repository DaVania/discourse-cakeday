# Discourse Private Cakeday

A fork of [discourse-cakeday](https://github.com/discourse/discourse-cakeday) with
two extra features that the upstream (now bundled into Discourse core) doesn't
provide:

- **Year-of-birth storage** with age display
- **Group-based privacy controls** — users can choose to hide their birthdate
  from everyone except themselves, staff, and explicit allow-listed groups

![](example.png)
![](example2.png)

## Why a fork?

Discourse 3.6+ bundles its own `discourse-cakeday` plugin into core. The bundled
version doesn't store birth-year and doesn't filter age visibility based on
group membership — both features this fork adds. Since the bundled plugin
shares the upstream plugin name, this fork ships under a different name
(`discourse-private-cakeday`) so it can be installed alongside / instead of
core's version.

## Installing

This plugin **replaces** Discourse's built-in cakeday. Both can't be active at
the same time.

1. Disable the bundled plugin:
   Admin → Settings → search "cakeday" → uncheck `cakeday enabled`
2. Add to your `app.yml` under `plugins:`:
   ```yaml
   - git clone https://github.com/babylai/discourse-private-cakeday.git
   ```
3. Rebuild the container
4. Enable: Admin → Settings → search "private cakeday" → check `private cakeday enabled`

See https://meta.discourse.org/t/install-a-plugin/19157/14 for general plugin
installation guidance.

## Site settings

All settings are prefixed `private_cakeday_*` so they don't collide with core's
`cakeday_*` namespace. Key options:

- `private_cakeday_enabled` — master switch
- `private_cakeday_birthday_show_year` — whether the year-of-birth selector
  appears in the user's date-of-birth preferences
- `private_cakeday_min_age_controlvisibility` — minimum age at which a user
  can choose to limit who sees their full birthdate (default: 18)
- `private_cakeday_show_age_to_groups` — groups that always see full
  birthdate regardless of the per-user visibility setting

## Co-existing with other plugins

`discourse-custom-ap-profile` (from version 0.2 onward, see
[the 2026.4 compat PR](https://github.com/DaVania/discourse-custom-ap-profile/pull/18))
detects this plugin and treats it as equivalent to bundled `discourse-cakeday`
for its PM age-gate and `add_to_group_by_min_age` automation scriptable.
Either plugin satisfies its `cakeday`-style dependency.

## Compatibility

- Discourse `main` / 2026.4+. Earlier versions may work but are not actively
  tested.
- Co-installable with `discourse-custom-ap-profile`.

## License

MIT
