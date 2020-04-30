# Stacker

Stacker is [Salt PillarStack](https://docs.saltstack.com/en/master/ref/pillar/all/salt.pillar.stack.html) in Crystal.

It is implemented using [crinja](https://github.com/straight-shoota/crinja) which is Jinja2 in Crystal :)

## Installation

To compile under Debian Buster you will need [Crystal](https://crystal-lang.org/install/on_debian/)

Then :

```sh
git clone https://github.com/jbox-web/stacker
make deps
make stacker-release
```

## Usage

Start the webserver with sample data :

```sh
bin/stacker server --config example/stacker.yml
```

Fetch pillars with Stacker :

```sh
bin/stacker fetch server1.example.net --config example/stacker.yml --grains example/grains/server1.json | jq
```

Fetch pillars with Curl :

```sh
curl --no-progress-meter -X POST -H "Content-Type: application/json" -d @example/grains/server1.json http://127.0.0.1:3000/server1.example.net | jq
```

You can also navigate to http://127.0.0.1:3000/server1.example.net to see the generated pillars.

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

## Debug

Set log level by exporting environment variable :

```sh
export CRYSTAL_LOG_LEVEL=debug
bin/stacker server --config example/stacker.yml
```
