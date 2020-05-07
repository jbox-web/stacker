# Stacker - A lightweight file-based CMDB

[![GitHub license](https://img.shields.io/github/license/jbox-web/stacker.svg)](https://github.com/jbox-web/stacker/blob/master/LICENSE)
[![Build Status](https://github.com/jbox-web/stacker/workflows/Stacker%20CI/badge.svg?branch=master)](https://github.com/jbox-web/stacker/actions)

Stacker is [Salt PillarStack](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html) in [Crystal](https://crystal-lang.org/).

It is implemented using [crinja](https://github.com/straight-shoota/crinja) which is Jinja2 in Crystal :)

## Installation

To compile under Debian Buster you will need [Crystal](https://crystal-lang.org/install/on_debian/)

Then :

```sh
git clone https://github.com/jbox-web/stacker
make deps
make stacker-release
```

## The 10 seconds test

Start the webserver with sample data :

```sh
bin/stacker server --config example/stacker.yml
```

Fetch pillars with Stacker :

```sh
bin/stacker fetch server1.example.net --config example/stacker.yml --grains example/grains/server1.json --pillar example/ext_pillar/server1.json | jq
```

Fetch pillars with Curl :

```sh
curl --no-progress-meter -X POST -H "Content-Type: application/json" -d @example/grains/server1.curl.json http://127.0.0.1:3000/server1.example.net | jq
```

You can also navigate to http://127.0.0.1:3000/server1.example.net to see the generated pillars.

## Configuration

By default Stacker looks for it's configuration file in the current directory.

You can pass an alternative path by using `--config` flag.

The configuration file is a YAML file looking like this :

```yml
---
doc_root: example/doc_root
entrypoint: server-pillars

stacks:
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
`stacks`             | a list of [stack configuration files](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html#list-of-config-files) (default [])
`server_host`        | ip address to bind to (default `127.0.0.1`)
`server_port`        | port to bind to (default `3000`)
`server_environment` | `development` or `production` (default `production`)

## Salt integration

To integrate Stacker with Salt you first need to add the [stacker pillar module](/salt/stacker.py) in Salt :

1. Declare extension modules directory in Salt (`/etc/salt/master.conf` or `/etc/salt/master.d/f_defaults.conf`)

```yml
extension_modules: /data/salt/modules
```

2. Create `/data/salt/modules/pillar` directory and puts [stacker module](/salt/stacker.py) in it

```sh
mkdir -p /data/salt/modules/pillar
wget -O /data/salt/modules/pillar/stacker.py https://raw.githubusercontent.com/jbox-web/stacker/master/salt/stacker.py
```

3. Declare the new ext_pillar module in Salt

```yml
ext_pillar:
  - stacker: http://127.0.0.1:3000
```

4. Restart Salt, you're done :)

## Scaling

The Stacker's web design leads to great possibilities :

* You can move Stacker and the pillar rendering out of Salt server :

```yml
ext_pillar:
  - stacker: http://stacker.example.corp:3000
```

* You can run multiple instances of Stacker and call them sequentially :

```yml
ext_pillar:
  - stacker: http://127.0.0.1:3000
  - stacker: http://127.0.0.1:4000
  - stacker: http://127.0.0.1:5000
```

With each instance having it's own stack configuration :)

## Template syntax

The [template syntax](https://github.com/straight-shoota/crinja/blob/master/TEMPLATE_SYNTAX.md) is almost the same than Jinja2.

Stacker adds a bunch of filters and functions :

* json filter (dump json without character escaping) (like the [Salt one](https://docs.saltstack.com/en/latest/topics/jinja/index.html#tojson))
* traverse filter (like the [Salt one](https://docs.saltstack.com/en/latest/topics/jinja/index.html#traverse))
* log function (like the [Salt one](https://docs.saltstack.com/en/latest/topics/jinja/index.html#logs))
* dump function
* array_push function
* merge_dict function

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
  json()
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

## Output format

Set output format by using optional query parameter :

```sh
curl http://127.0.0.1:3000/server1.example.net?f=json
curl http://127.0.0.1:3000/server1.example.net?f=yaml
```

Default output format is `json`.

Only `json` and `yaml` are supported.

## Logs

Set log level by using optional query parameter :

```sh
curl http://127.0.0.1:3000/server1.example.net?l=verbose
curl http://127.0.0.1:3000/server1.example.net?l=debug
```

Log levels other than `verbose` or `debug` are meaningless.

`debug` level is very verbose as it dumps data before and after merge operations.

`verbose` level will render something like this :

```sh
V, [2020-05-06T02:08:39.049901000Z #188552] VERBOSE -- stacker:stacker: Looking for example/doc_root/server-pillars/server2.example.net.yml
V, [2020-05-06T02:08:39.050019000Z #188552] VERBOSE -- stacker:stacker: Building stack for: server2.example.net
V, [2020-05-06T02:08:39.050405000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/server-pillars/01-common.yml"] from example/doc_root/server-pillars
V, [2020-05-06T02:08:39.050532000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/server-pillars/01-common.yml
V, [2020-05-06T02:08:39.050855000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/server-pillars/01-common.yml
V, [2020-05-06T02:08:39.051022000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/server-pillars/server2.example.net.yml"] from example/doc_root/server-pillars
V, [2020-05-06T02:08:39.051141000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/server-pillars/server2.example.net.yml
V, [2020-05-06T02:08:39.052889000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/server-pillars/server2.example.net.yml
V, [2020-05-06T02:08:39.053613000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/01-base/01-base.yml", "example/doc_root/pillars/01-base/app1.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.053734000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/01-base/01-base.yml
V, [2020-05-06T02:08:39.054108000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/01-base/01-base.yml
V, [2020-05-06T02:08:39.054241000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/01-base/app1.yml
V, [2020-05-06T02:08:39.054513000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/01-base/app1.yml
V, [2020-05-06T02:08:39.054759000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/02-common/syslog.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.054923000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/02-common/syslog.yml
V, [2020-05-06T02:08:39.056943000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/02-common/syslog.yml
V, [2020-05-06T02:08:39.057113000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/common-locale.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.057233000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/common-locale.yml
V, [2020-05-06T02:08:39.057729000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/common-locale.yml
V, [2020-05-06T02:08:39.057891000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/common-timezone.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.058011000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/common-timezone.yml
V, [2020-05-06T02:08:39.058526000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/common-timezone.yml
V, [2020-05-06T02:08:39.058714000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/common-users.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.058806000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/common-users.yml
V, [2020-05-06T02:08:39.059615000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/common-users.yml
V, [2020-05-06T02:08:39.059784000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/client-salt.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.059905000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/client-salt.yml
V, [2020-05-06T02:08:39.060465000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/client-salt.yml
V, [2020-05-06T02:08:39.060636000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/server-openssh.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.060755000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/server-openssh.yml
V, [2020-05-06T02:08:39.061561000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/server-openssh.yml
V, [2020-05-06T02:08:39.061733000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/server-docker.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.061846000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/server-docker.yml
V, [2020-05-06T02:08:39.062689000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/server-docker.yml
V, [2020-05-06T02:08:39.062880000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/server-nodejs.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.063001000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/server-nodejs.yml
V, [2020-05-06T02:08:39.063995000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/server-nodejs.yml
V, [2020-05-06T02:08:39.064181000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/server-php.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.064279000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/server-php.yml
V, [2020-05-06T02:08:39.065910000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/server-php.yml
V, [2020-05-06T02:08:39.066102000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/03-roles/server-redis.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.066227000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/03-roles/server-redis.yml
V, [2020-05-06T02:08:39.066966000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/03-roles/server-redis.yml
V, [2020-05-06T02:08:39.067172000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/04-roles-config/php-app-server-common.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.067292000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/04-roles-config/php-app-server-common.yml
V, [2020-05-06T02:08:39.068349000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/04-roles-config/php-app-server-common.yml
V, [2020-05-06T02:08:39.068544000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/pillars/04-roles-config/php-app-server-development.yml"] from example/doc_root/pillars
V, [2020-05-06T02:08:39.068691000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/pillars/04-roles-config/php-app-server-development.yml
V, [2020-05-06T02:08:39.075023000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/pillars/04-roles-config/php-app-server-development.yml
V, [2020-05-06T02:08:39.075755000Z #188552] VERBOSE -- stacker:stacker: Loading: ["example/doc_root/server-pillars/server2.example.net/dump.yml", "example/doc_root/server-pillars/server2.example.net/users.yml"] from example/doc_root/server-pillars
V, [2020-05-06T02:08:39.075856000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/server-pillars/server2.example.net/dump.yml
V, [2020-05-06T02:08:39.076636000Z #188552] VERBOSE -- stacker:stacker: Compiling: example/doc_root/server-pillars/server2.example.net/users.yml
V, [2020-05-06T02:08:39.077523000Z #188552] VERBOSE -- stacker:stacker: Merging: example/doc_root/server-pillars/server2.example.net/users.yml
V, [2020-05-06T02:08:39.077650000Z #188552] VERBOSE -- stacker:stacker: End of stack build for: server2.example.net
2020-05-06 02:08:39 UTC 200 GET /server2.example.net?l=verbose 29.54ms
```

## Roadmap

* implement [merging-strategies](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html#merging-strategies)
