# -*- coding: utf-8 -*-

import logging
import json
import salt.utils.http

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

  data = json.dumps({ 'grains': __grains__, 'pillar': pillar })

  result = salt.utils.http.query(
    host,
    method = 'POST',
    params = params,
    data = data,
    header_dict = { 'Content-Type': 'application/json' }
  )

  if 'body' in result:
    result = result['body']
    result = json.loads(result)

    if result == {'404': 'Not found'}:
      log.warning("Error while contacting Stacker for %s : %s" % (minion_id, result))
      return {}
    else:
      return result

  else:
    log.error("Error while contacting Stacker for %s : %s" % (minion_id, result))
    return {}
