# wright NEWS
## unreleased
- Add --dry-run option
- Add support for virtual packages to apt provider

## 0.3.0 (2015-04-23)
- Add bin/wright
- Add wright(1) manpage
- Add OS X user provider
- Improve performance of the apt provider
- Improve error message for resources without names (#5)
- Improve error message for symlinks without target (#6)

## 0.2.0 (2015-03-13)
- Add Homebrew package provider for OS X
- Add group resource
  - Add group provider for GNU systems
  - Add group provider for OS X
- Add user resource (provider)
  - Add user provider for GNU systems
- Fix name error in symlink provider
- Add `Provider#exec_or_fail`
- Pass arguments to `Open3::capture3` properly

## 0.1.2 (2015-01-31)
- Convert docs to YARD
- Fix color code for warnings

## 0.1.1 (2015-01-20)
- Remove hardcoded package provider config
- Specify Ruby version in gemspec

## 0.1.0 (2015-01-16)
- First public release
