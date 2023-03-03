#!/bin/bash
#WARNING: You can only ever get a max of 10000 results!  Use filters to cut it down or do searches in smaller chunks!

EHOST="http://localhost:9200"

curl -k -PUT "${EHOST}/signals/_search?size=10000&pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "must": [],
      "filter": [
        {
          "match_phrase": {
            "Network": "Comcast"
          }
        },
        {
          "match_phrase": {
            "Status": "offline"
          }
        },
        {
          "range": {
           "Time": {
              "gte": "now-1d/d",
              "lt": "now"
            }
          }

        }
      ],
      "should": [],
      "must_not": []
    }
  },
  "sort": {
    "Time": {
      "order": "asc"
    }
  }
}
'
