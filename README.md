# Stacker - A lightweight file-based CMDB

[![GitHub license](https://img.shields.io/github/license/jbox-web/stacker.svg)](https://github.com/jbox-web/stacker/blob/master/LICENSE)
[![Build Status](https://github.com/jbox-web/stacker/workflows/Stacker%20CI/badge.svg?branch=master)](https://github.com/jbox-web/stacker/actions)

Stacker is [Salt PillarStack](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html) in [Crystal](https://crystal-lang.org/).

It is implemented using [crinja](https://github.com/straight-shoota/crinja) which is Jinja2 in Crystal :)

[Documentation](https://jbox-web.github.io/stacker/index.html)

## Installation

### Manual compilation

To compile under Debian Buster you will need [Crystal](https://crystal-lang.org/install/on_debian/)

Then :

```sh
git clone https://github.com/jbox-web/stacker
make stacker-release
```

### Docker

In this case you will need... Docker.

Then :

```sh
docker pull nicoladmin/stacker:nightly
```

**Note :** The Docker mode comes with a [wrapper script](https://github.com/jbox-web/stacker/blob/master/stacker.sh) to ease interactions with the container

Usage : `stacker.sh {start|stop|restart|status|kill|clean|fetch|logs}`

## The 10 seconds test in Web mode

First we need to start Stacker with sample data :

### Manual compilation

```sh
bin/stacker server --config example/stacker.yml
```

### Docker

```sh
./stacker.sh start
```

Then fetch pillars with Curl :

```sh
curl --no-progress-meter -X POST -H "Content-Type: application/json" -d @example/grains/server1.curl.json http://127.0.0.1:3000/server1.example.net | jq
```

You can also navigate to http://127.0.0.1:3000/server1.example.net to see the generated pillars.

## The 10 seconds test in CLI mode

In this mode you don't need the webserver to be running :

### Manual compilation

```sh
bin/stacker fetch server1.example.net --config example/stacker.yml --grains example/grains/server1.json --pillar example/ext_pillar/server1.json | jq
```

### Docker

```sh
./stacker.sh fetch server1.example.net --grains grains/server1.json --pillar ext_pillar/server1.json | jq
```

## Usage

```sh
Usage:
  bin/stacker [flags...] [arg...]

Stacker is Salt PillarStack in Crystal

Flags:
  --help     # Displays help for the current command.
  --version  # Displays the version of the current application.

Subcommands:
  fetch      # Fetch host pillars
  info       # Show Stacker information
  server     # Run Stacker webserver
```

## Configuration

By default Stacker looks for it's configuration file in the current directory (`stacker.yml`).

You can pass an alternative file by using `--config` flag.

The configuration file is a YAML file looking like this :

```yml
---
doc_root: example/doc_root
entrypoint: server-pillars
log_file: ./log/stacker.log

stacks:
  default:
    - example/doc_root/server-pillars/stack1.cfg
  dev:
    - example/doc_root/server-pillars/stack1.cfg
    - example/doc_root/pillars/stack1.cfg
  prod:
    - example/doc_root/server-pillars/stack1.cfg
    - example/doc_root/pillars/stack1.cfg
    - example/doc_root/server-pillars/stack2.cfg

server_host: 127.0.0.1
server_port: 3000
server_environment: development
```

**Note :** You can use relative or absolute file path.

Config               | Description
---------------------|------------
`doc_root`           | the webserver document root (must be specified). Since pillar are also crinja templates, it means where are the template files?
`entrypoint`         | the webserver entrypoint (must be specified). The directory in the `doc_root` where we shoud look for `<minion_d>.yml` file
`log_file`           | the path to the log file
`stacks`             | a hash of namespaced [stack configuration files](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html#list-of-config-files) (must be specified)
`server_host`        | ip address to bind to (default `127.0.0.1`)
`server_port`        | port to bind to (default `3000`)
`server_environment` | `development` or `production` (default `production`)

## Salt integration

To integrate Stacker with Salt you first need to add the [stacker pillar module](/salt/stacker.py) in Salt :

1. Declare extension modules directory in Salt (`/etc/salt/master.conf` or `/etc/salt/master.d/f_defaults.conf`)

```yml
extension_modules: /data/salt/modules
```

2. Create `/data/salt/modules/pillar` directory and puts [stacker module](https://github.com/jbox-web/stacker/blob/master/salt/stacker.py) in it

```sh
mkdir -p /data/salt/modules/pillar
wget -O /data/salt/modules/pillar/stacker.py https://raw.githubusercontent.com/jbox-web/stacker/master/salt/stacker.py
```

3. Declare the new ext_pillar module in Salt

```yml
ext_pillar:
  - stacker: http://127.0.0.1:3000
```

You can also pass parameters to Stacker module :

```yml
ext_pillar:
  - stacker:
      host: http://127.0.0.1:3000
      namespace: 'production'
      log_level: 'debug'
```

4. Restart Salt, you're done :)

## Namespaces

Use namespaces by using optional `n=` query parameter :

```sh
curl http://127.0.0.1:3000/server1.example.net?n=dev
curl http://127.0.0.1:3000/server1.example.net?n=prod
```

Or with `--namespace` flag when using Stacker CLI.

The default namespace when query parameter or CLI flag is omited is `default`.

## Output format

Set output format by using optional `f=` query parameter :

```sh
curl http://127.0.0.1:3000/server1.example.net?f=json
curl http://127.0.0.1:3000/server1.example.net?f=yaml
```

Or with `--output-format` flag when using Stacker CLI.

The default output format when query parameter or CLI flag is omited is `json`.

Only `json` and `yaml` are supported.

## Logs

* log level

The log level is dynamic. No need to restart the web server :)

Set log level by using optional `l=` query parameter :

```sh
curl http://127.0.0.1:3000/server1.example.net?l=debug
curl http://127.0.0.1:3000/server1.example.net?l=trace
```

Or with `--log-level` flag when using Stacker CLI.

The default log level when query parameter or CLI flag is omited is `info`.

Log levels other than `debug` or `trace` are meaningless.

`trace` level is very verbose as it dumps data before and after merge operations. In this case you might need some filtering, see below...

<details><summary>debug level will render something like this :</summary>

```sh
2020-10-02T23:18:27.149678Z   INFO - processor: Building stack for: server2.example.net (namespace: prod)
2020-10-02T23:18:27.149897Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/stack1.cfg
2020-10-02T23:18:27.149927Z  DEBUG - processor: Loading: example/doc_root/server-pillars/01-base.yml
2020-10-02T23:18:27.149936Z  DEBUG - processor: Compiling: example/doc_root/server-pillars/01-base.yml
2020-10-02T23:18:27.150030Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/01-base.yml
2020-10-02T23:18:27.150078Z  DEBUG - processor: Merging: example/doc_root/server-pillars/01-base.yml
2020-10-02T23:18:27.150099Z  DEBUG - processor: Loading: example/doc_root/server-pillars/server2.example.net.yml
2020-10-02T23:18:27.150109Z  DEBUG - processor: Compiling: example/doc_root/server-pillars/server2.example.net.yml
2020-10-02T23:18:27.150190Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/server2.example.net.yml
2020-10-02T23:18:27.150263Z  DEBUG - processor: Merging: example/doc_root/server-pillars/server2.example.net.yml
2020-10-02T23:18:27.150705Z  DEBUG - renderer: Compiled: example/doc_root/pillars/stack1.cfg
2020-10-02T23:18:27.150775Z  DEBUG - processor: Loading: example/doc_root/pillars/01-base/01-base.yml
2020-10-02T23:18:27.150784Z  DEBUG - processor: Compiling: example/doc_root/pillars/01-base/01-base.yml
2020-10-02T23:18:27.150873Z  DEBUG - renderer: Compiled: example/doc_root/pillars/01-base/01-base.yml
2020-10-02T23:18:27.150932Z  DEBUG - processor: Merging: example/doc_root/pillars/01-base/01-base.yml
2020-10-02T23:18:27.150942Z  DEBUG - processor: Loading: example/doc_root/pillars/01-base/app1.yml
2020-10-02T23:18:27.150949Z  DEBUG - processor: Compiling: example/doc_root/pillars/01-base/app1.yml
2020-10-02T23:18:27.151042Z  DEBUG - renderer: Compiled: example/doc_root/pillars/01-base/app1.yml
2020-10-02T23:18:27.151091Z  DEBUG - processor: Merging: example/doc_root/pillars/01-base/app1.yml
2020-10-02T23:18:27.151108Z  DEBUG - processor: Loading: example/doc_root/pillars/01-base/zdump.yml
2020-10-02T23:18:27.151115Z  DEBUG - processor: Compiling: example/doc_root/pillars/01-base/zdump.yml
2020-10-02T23:18:27.151208Z  DEBUG - renderer: Compiled: example/doc_root/pillars/01-base/zdump.yml
2020-10-02T23:18:27.151238Z  DEBUG - processor: Merging: example/doc_root/pillars/01-base/zdump.yml
2020-10-02T23:18:27.151267Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/common/locale.yml
2020-10-02T23:18:27.151286Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/common/locale.yml
2020-10-02T23:18:27.151392Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/common/locale.yml
2020-10-02T23:18:27.151426Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/common/locale.yml
2020-10-02T23:18:27.151452Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/common/timezone.yml
2020-10-02T23:18:27.151462Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/common/timezone.yml
2020-10-02T23:18:27.151572Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/common/timezone.yml
2020-10-02T23:18:27.151597Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/common/timezone.yml
2020-10-02T23:18:27.151619Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/common/users.yml
2020-10-02T23:18:27.151627Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/common/users.yml
2020-10-02T23:18:27.151795Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/common/users.yml
2020-10-02T23:18:27.151858Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/common/users.yml
2020-10-02T23:18:27.151879Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/client/salt.yml
2020-10-02T23:18:27.151887Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/client/salt.yml
2020-10-02T23:18:27.152009Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/client/salt.yml
2020-10-02T23:18:27.152039Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/client/salt.yml
2020-10-02T23:18:27.152060Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/server/openssh.yml
2020-10-02T23:18:27.152069Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/server/openssh.yml
2020-10-02T23:18:27.152231Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/server/openssh.yml
2020-10-02T23:18:27.152331Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/server/openssh.yml
2020-10-02T23:18:27.152351Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/server/docker.yml
2020-10-02T23:18:27.152360Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/server/docker.yml
2020-10-02T23:18:27.152478Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/server/docker.yml
2020-10-02T23:18:27.152528Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/server/docker.yml
2020-10-02T23:18:27.152547Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/server/nodejs.yml
2020-10-02T23:18:27.152554Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/server/nodejs.yml
2020-10-02T23:18:27.152688Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/server/nodejs.yml
2020-10-02T23:18:27.152729Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/server/nodejs.yml
2020-10-02T23:18:27.152748Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/server/php.yml
2020-10-02T23:18:27.152756Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/server/php.yml
2020-10-02T23:18:27.152931Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/server/php.yml
2020-10-02T23:18:27.153030Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/server/php.yml
2020-10-02T23:18:27.153050Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/server/redis.yml
2020-10-02T23:18:27.153059Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/server/redis.yml
2020-10-02T23:18:27.153534Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/server/redis.yml
2020-10-02T23:18:27.153604Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/server/redis.yml
2020-10-02T23:18:27.153631Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/custom/php-app-server-common.yml
2020-10-02T23:18:27.153639Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/custom/php-app-server-common.yml
2020-10-02T23:18:27.153759Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/custom/php-app-server-common.yml
2020-10-02T23:18:27.153835Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/custom/php-app-server-common.yml
2020-10-02T23:18:27.153856Z  DEBUG - processor: Loading: example/doc_root/pillars/02-roles/custom/php-app-server-development.yml
2020-10-02T23:18:27.153864Z  DEBUG - processor: Compiling: example/doc_root/pillars/02-roles/custom/php-app-server-development.yml
2020-10-02T23:18:27.154676Z  DEBUG - renderer: Compiled: example/doc_root/pillars/02-roles/custom/php-app-server-development.yml
2020-10-02T23:18:27.154824Z  DEBUG - processor: Merging: example/doc_root/pillars/02-roles/custom/php-app-server-development.yml
2020-10-02T23:18:27.154931Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/stack2.cfg
2020-10-02T23:18:27.154970Z  DEBUG - processor: Loading: example/doc_root/server-pillars/server2.example.net/clean.yml
2020-10-02T23:18:27.154978Z  DEBUG - processor: Compiling: example/doc_root/server-pillars/server2.example.net/clean.yml
2020-10-02T23:18:27.155054Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/server2.example.net/clean.yml
2020-10-02T23:18:27.155076Z  DEBUG - processor: Merging: example/doc_root/server-pillars/server2.example.net/clean.yml
2020-10-02T23:18:27.155086Z  DEBUG - processor: Loading: example/doc_root/server-pillars/server2.example.net/stacker.yml
2020-10-02T23:18:27.155090Z  DEBUG - processor: Compiling: example/doc_root/server-pillars/server2.example.net/stacker.yml
2020-10-02T23:18:27.155162Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/server2.example.net/stacker.yml
2020-10-02T23:18:27.155181Z  DEBUG - processor: Merging: example/doc_root/server-pillars/server2.example.net/stacker.yml
2020-10-02T23:18:27.155191Z  DEBUG - processor: Loading: example/doc_root/server-pillars/server2.example.net/users.yml
2020-10-02T23:18:27.155195Z  DEBUG - processor: Compiling: example/doc_root/server-pillars/server2.example.net/users.yml
2020-10-02T23:18:27.155451Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/server2.example.net/users.yml
2020-10-02T23:18:27.155475Z  DEBUG - processor: Merging: example/doc_root/server-pillars/server2.example.net/users.yml
2020-10-02T23:18:27.155486Z  DEBUG - processor: Loading: example/doc_root/server-pillars/server2.example.net/zdump.yml
2020-10-02T23:18:27.155490Z  DEBUG - processor: Compiling: example/doc_root/server-pillars/server2.example.net/zdump.yml
2020-10-02T23:18:27.155896Z  DEBUG - renderer: Compiled: example/doc_root/server-pillars/server2.example.net/zdump.yml
2020-10-02T23:18:27.156648Z  DEBUG - processor: Merging: example/doc_root/server-pillars/server2.example.net/zdump.yml
2020-10-02T23:18:27.156664Z   INFO - processor: End of stack build for: server2.example.net (namespace: prod)
```
</details>

* filter logs by template path

Set the file path to debug by using optional `p=` query parameter :

```sh
curl http://127.0.0.1:3000/server1.example.net?l=trace&p=doc_root/pillars/02-roles/server/openssh.yml
```

Or with `--path` flag when using Stacker CLI.

* filter logs by steps

Set the step to debug by using optional `s=` query parameter :

```sh
curl http://127.0.0.1:3000/server1.example.net?l=trace&p=doc_root/pillars/02-roles/server/openssh.yml&s=compile,yaml-load
```

Or with `--step` flag when using Stacker CLI.

Valid options for the `step` param are : `compile` | `yaml-load` | `before-merge` | `after-merge` | `final`

## Scaling

The Stacker's web design leads to great possibilities :

* You can move Stacker and the pillar rendering process out of Salt server :

```yml
ext_pillar:
  - stacker: http://stacker.example.corp:3000
```

* You can run multiple instances of Stacker and call them sequentially :

```yml
ext_pillar:
  - stacker: http://127.0.0.1:3000?n=foo
  - stacker: http://127.0.0.1:4000?n=bar
  - stacker: http://127.0.0.1:5000?n=baz
```

With each instance having it's own stack configuration :)

## Deployment

You can use the [provided systemd unit](https://github.com/jbox-web/stacker/blob/master/extra/stacker.service) to manage the Stacker daemon.

## Merging strategies

Stacker implements [merging strategies](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html#merging-strategies) like PillarStack so you can use them in Stacker too :)

It works the same way and it's [tested](/spec/stacker/value_spec.cr#L45).

## Template syntax

The [template syntax](https://github.com/straight-shoota/crinja/blob/master/TEMPLATE_SYNTAX.md) is almost the same than Jinja2.

[Like PillarStack](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html#overall-process) you have access to these variables :

* `stack`
* `pillar`
* `minion_id`
* `grains` (instead of `__grains__`)

Stacker adds a bunch of filters and functions :

Filters :

* json filter (dump json without character escaping) (like the [Salt one](https://docs.saltstack.com/en/latest/topics/jinja/index.html#tojson))
* traverse filter (like the [Salt one](https://docs.saltstack.com/en/latest/topics/jinja/index.html#traverse))
* unique filter (like the [Salt one](https://docs.saltstack.com/en/latest/topics/jinja/index.html#unique))

Functions :

* log function (like the [Salt one](https://docs.saltstack.com/en/latest/topics/jinja/index.html#logs))
* dump function (it dumps objects to YAML in log file)
* array_push function
* merge_dict function

You can see examples of code in the [documentation](https://jbox-web.github.io/stacker/Stacker/Runtime/Filter/Json.html).

The following filters/tests/functions/tags/operators are supported :

```
filters:
  abs()
  append(string=)
  attr(name=)
  batch(linecount=2, fill_with=none)
  capitalize()
  center(width=80)
  date(format=)
  default(default_value='', boolean=false)
  dictsort(case_sensitive=false, by='key')
  escape()
  filesizeformat(binary=false)
  first()
  float(default=0.0)
  forceescape()
  format()
  groupby(attribute=)
  indent(width=4, indentfirst=false)
  int(default=0, base=10)
  join(separator='', attribute=none)
  json(indent=none)
  last()
  length()
  list()
  lower()
  map()
  pprint(verbose=false)
  prepend(string=)
  random()
  reject()
  rejectattr()
  replace(old=, new=, count=none)
  reverse()
  round(precision=0, method='common', base=10)
  safe()
  select()
  selectattr()
  slice(slices=2, fill_with=none)
  sort(reverse=false, case_sensitive=false, attribute=none)
  string()
  striptags()
  sum(attribute=none, start=0)
  title()
  tojson(indent=none)
  traverse(attribute=none, default=none)
  trim()
  truncate(length=255, killwords=false, end='...', leeway=none)
  unique()
  upper()
  urlencode()
  urlize(trim_url_limit=none, nofollow=false, target=none, rel=none)
  wordcount()
  wordwrap(width=79, break_long_words=true, wrapstring=none)
  xmlattr(autoescape=true)

tests:
  callable()
  defined()
  divisibleby(num=)
  equalto(other=)
  escaped()
  even()
  greaterthan(other=0)
  in(seq=[])
  iterable()
  lessthan(other=0)
  lower()
  mapping()
  nil()
  none()
  number()
  odd()
  sameas(other=)
  sequence()
  string()
  undefined()
  upper()

functions:
  array_push(array=[], item=none)
  cycler()
  debug()
  dict()
  dump(object=none)
  joiner(sep=', ')
  log(object=none)
  merge_dict(hash=none, other=none)
  range(start=0, stop=0, step=1)
  super()

tags:
  autoescape~endautoescape
  block~endblock
  call~endcall
  do
  elif
  else
  endautoescape
  endblock
  endcall
  endfilter
  endfor
  endif
  endmacro
  endraw
  endset
  endwith
  extends
  filter~endfilter
  for~endfor
  from
  if~endif
  import
  include
  macro~endmacro
  raw~endraw
  set~endset
  with~endwith

operators:
  operator[!=]
  operator[%]
  operator[*]
  operator[**]
  operator[+]
  operator[-]
  operator[/]
  operator[//]
  operator[<]
  operator[<=]
  operator[==]
  operator[>]
  operator[>=]
  operator[and]
  operator[not]
  operator[or]
  operator[~]
```

## Extend Stacker

If you need to add filters (or functions) just drop a new class with a few lines of Crystal code in [/src/runtime](https://github.com/jbox-web/stacker/tree/master/src/runtime) and recompile Stacker with `make stacker` (dev mode) or `make stacker-release` (release mode).

Your custom filters (or functions) should be available in Jinja templates. To be sure run `stacker info` and check the Crinja environment info.

Then feel free to submit a PR if you think it will be useful for people.

**Note:** `make stacker-static` only works on Alpine Linux because it's the only distribution where Crystal supports static linking.

## Roadmap

* implement [Select Stacker config through grains|pillar|opts matching](https://github.com/saltstack/salt/blob/a670b4ae72ec11f5485c216c54059e14223019b8/salt/pillar/stack.py#L77)
* add documentation about "Stacker - Sample Project"
