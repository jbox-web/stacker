# -*- coding: utf-8 -*-
"""
Custom ``ext_pillar`` that fetches pillar data over HTTP from an external
"Stacker" service. Coexists with PillarStack (``modules/pillar/stack.py``) and
is wired in the master ``ext_pillar`` list.

Config args (positional or kwargs):

.. code-block:: yaml

    ext_pillar:
      - stacker:
          host: https://stacker.example   # required; base URL
          namespace: prod                  # optional -> query param ``n``
          log_level: debug                 # optional -> query param ``l``

For each minion the module POSTs ``{"grains": ..., "pillar": ...}`` (JSON) to
``<host>/<minion_id>`` and merges the JSON response into the pillar. Returns an
empty dict when ``host`` is null or on a Stacker 404 (namespace/host not
found). Raises when Stacker cannot answer (transport error, non-200 status,
unreadable body): Salt then reports a pillar error and refuses to run states,
instead of applying them with an empty pillar.
"""

import logging
import json
import salt.utils.http
from salt.exceptions import SaltException

log = logging.getLogger(__name__)

def ext_pillar(minion_id, pillar, *args, **kwargs):
  host      = kwargs.get('host', None) or args[0]
  namespace = kwargs.get('namespace', None)
  log_level = kwargs.get('log_level', None)

  if host == None:
    log.warning("Cannot contact Stacker with host null")
    return {}

  host = '%s/%s' % (host, minion_id)
  params = {}

  if log_level != None:
    params['l'] = log_level

  if namespace != None:
    params['n'] = namespace

  data = json.dumps({ 'grains': __grains__.value(), 'pillar': pillar })

  result = salt.utils.http.query(
    host,
    method = 'POST',
    params = params,
    data = data,
    header_dict = { 'Content-Type': 'application/json' },
    status = True
  )

  if 'body' not in result:
    raise SaltException("Cannot contact Stacker for %s: %s" % (minion_id, result.get('error', result)))

  try:
    body = json.loads(result['body'])
  except ValueError as exc:
    raise SaltException("Unreadable Stacker answer for %s: %s" % (minion_id, exc))

  if body == {'404': 'Stacker: namespace not found'} or body == {'404': 'Stacker: host not found'}:
    log.warning("Error while contacting Stacker for %s : %s" % (minion_id, body))
    return {}

  if result.get('status', 200) != 200:
    raise SaltException("Stacker answered %s for %s" % (result.get('status'), minion_id))

  return body
