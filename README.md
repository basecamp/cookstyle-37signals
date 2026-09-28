# cookstyle-37signals

Cookstyle configuration and custom cops for 37signals' Chef cookbooks.

A cookbook's `.rubocop.yml` inherits this gem as well as [house style](https://github.com/basecamp/house-style):

```yaml
inherit_from:
  - https://raw.githubusercontent.com/basecamp/house-style/refs/heads/main/rubocop-ruby.yml

inherit_gem:
  cookstyle-37signals: config/default.yml
```

## What it checks

`config/default.yml` does the following:

- Enables every Chef cop that Cookstyle enables by default. House style sets
  `AllCops: DisabledByDefault: true`, which disables each cop that a config does not enable by
  name, so `config/chef.yml` lists the cops one by one.
- Sets `TargetRubyVersion` to 3.1, the Ruby in cinc-client 18.
- Requires string keys for node attributes (`Chef/Style/AttributeKeys`).
- Checks the format of `# TODO: ` and `# FIXME: ` comments (`Style/CommentAnnotation`).
- Loads these custom cops:

| Cop | Rule | Severity |
|-----|------------------|----------|
| `Cookbook/ExecuteGuard` | Guard every `execute`, `bash` and `script` resource with `not_if`, `only_if` or `creates`, unless it has `action :nothing`. | convention |
| `Cookbook/CronD` | Use `cron_d`, not `cron`. | convention |
| `Cookbook/CronDLogger` | Pipe a `cron_d` command's output to the journal with `2>&1 \| logger -t <tag>`. | info |
| `Cookbook/LocalIncludeRecipe` | Include recipes from the same cookbook as `"::recipe"`. Correctable. | convention |
| `Cookbook/SensitiveSecret` | Set `sensitive true` on a resource that uses a secret from a data bag or vault item. | info |
| `Cookbook/UnderscoreRunList` | Put a top-level role recipe in a policy's run list, not an underscore recipe. Checks `policyfiles/*.rb` only, not the root `Policyfile.rb` that test-kitchen uses. | convention |

Offenses with info severity are reported but do not fail the run.

When a resource breaks a rule on purpose, disable the cop on that line and give the reason:

```ruby
execute "apt-get update" do # rubocop:disable Cookbook/ExecuteGuard -- updates the package lists on every converge
```

### Templates and static files

Cookstyle checks only Ruby files. The `cookbook-lint` command checks the rest of a cookbook:

- Warns about a template that does not have the "Chef managed content" header in its first five
  lines. JSON and `.sync-metadata` templates, empty templates, and partials that another template
  renders are exempt.
- Warns about a script in `files/` that has a shebang line but no header.
- Reports an error for a file in `files/` that contains a literal `#{cookbook_name}` or
  `#{recipe_name}`. `cookbook_file` copies files verbatim, so the name is not interpolated.

Run it in a cookbook's root directory, with no arguments to check every template and file, or
with a list of paths to check only those. It exits 1 when there are errors.

## Running it

Cookstyle's binstub passes `--fail-level C` unless it is given a fail level, and most Chef cops
report offenses with refactor severity. Pass `--fail-level R` to make those offenses fail:

```
cookstyle --fail-level R
cookbook-lint
```

Run both in a pre-commit hook and in CI.

## Installing

`bin/setup` builds the gem and installs it into the Ruby that runs `cookstyle`. On a workstation
that is usually cinc-workstation's embedded Ruby, so the gem goes into the user gem directory
(`~/.chef/gem`). The script also links `cookbook-lint` into `~/.local/bin`.

Run `bin/setup` again after each pull to install the version on `main`.

## CI

`bin/ci` installs this gem from `main` and runs `cookstyle --fail-level R` and `cookbook-lint` in
the current directory. Run it in a `cincproject/workstation` image that ships the same Cookstyle
version as your workstations, for example as a Buildkite step:

```yaml
- label: ":rubocop: Lint"
  command: "git clone --depth 1 https://github.com/basecamp/cookstyle-37signals /tmp/cookstyle-37signals && /tmp/cookstyle-37signals/bin/ci"
  plugins:
    - docker#v5.3.0:
        image: "cincproject/workstation:26.0.1"
  notify:
    - github_commit_status:
        context: "buildkite/lint"
```

The `notify` block posts a separate GitHub status for this step, next to the status for the whole
build.

## Upgrading Cookstyle

When cinc-workstation ships a new Cookstyle:

1. Run `bin/generate-chef-config` with the Ruby that runs Cookstyle, for example
   `/opt/cinc-workstation/embedded/bin/ruby bin/generate-chef-config`, to update `config/chef.yml`.
2. Update the `cincproject/workstation` image tag in CI, and the Cookstyle version in
   `.github/workflows/ci.yml`.
3. Run Cookstyle against every cookbook and correct the new offenses before merging.

## Tests

```
rake test
```
