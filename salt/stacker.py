# -*- coding: utf-8 -*-

import logging
import json
import salt.utils.http

log = logging.getLogger(__name__)

def ext_pillar(minion_id, pillar, stacker_host):
  host = '%s/%s' % (stacker_host, minion_id)
  data = { 'grains': __grains__, 'pillar': pillar }
  data = json.dumps(data)

  result = salt.utils.http.query(
    host,
    method = 'POST',
    data = data,
    header_dict = { 'Content-Type': 'application/json' }
  )

  result = result['body']
  result = json.loads(result)

  if result == {'404': 'Not found'}:
    log.warning("Error while contacting Stacker for %s : %s" % (minion_id, result))
  else:
    return result
