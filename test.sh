echo "record type"

# term query
# curl 'http://localhost:9200/test1/_search?pretty' -d '{
#   "size" : 0,
#   "aggs" : {
#     "doc_types" : {
#       "terms" : { "field" : "project" }
#     }
#   }
# }
# '

# match query
# curl 'http://localhost:9200/test1/_search?pretty' -d '{
#   "size" : 20,
#   "query" : {
#     "must" : {
#       "match" : { }
#     }
#   }
# }
# '

# nested aggregation
# curl 'http://localhost:9200/test1/_search?pretty' -d '{
#   "size" : 0,
#   "aggs" : {
#     "testing" : {
#       "nested" : {
#         "path" : "person"
#       },
#       "aggs" : { 
#         "random_name" : {
#           "terms" : { "field" : "person.role" }
#         }
#       }
#     }
#   }
# }
# '

# nested term query
# curl 'http://localhost:9200/test1/_search?pretty' -d '{
#   "size" : 0,
#   "query": {
#     "bool": {
#       "must": {
#         "match_all": {
#         }
#       },
#       "filter": [
#         {
#           "term": {
#             "category": "Writings"
#           }
#         },
#         {
#           "nested" : {
#             "path" : "creator",
#             "query" : {
#               "term" : {
#                 "creator.name" : "Cather, Willa, 1873-1947"
#               }
#             }
#           }
#         }
#       ]
#     }
#   }
# }
# '

# date aggregation by year
curl 'http://localhost:9200/test1/_search?pretty' -d '{
  "size" : 0,
  "aggs" : {
    "year" : {
      "date_histogram" : {
        "field" : "date",
        "interval" : "year",
        "format" : "yyyy",
        "min_doc_count" : 1,
        "size" : 5
      }
    }
  }
}
'

# date filtered by year
# curl 'http://localhost:9200/test1/_count?pretty' -d '{
#   "query" : {
#     "bool" : {
#       "must" : {
#         "match_all" : {}
#       },
#       "filter" : [
#         {
#           "range" : {
#             "date" : {
#               "gte" : "1887-01-01",
#               "lte" : "1887-12-31",
#               "format" : "yyyy-MM-dd"
#             }
#           }
#         }
#       ]
#     }
#   }
# }
# '

# filtered by places empty string
# curl 'http://localhost:9200/test1/_count?pretty' -d '{
#   "query" : {
#     "bool" : {
#       "must" : {
#         "match_all" : {}
#       },
#       "filter" : [
#         {
#           "term" : {
#             "places" : ""
#           }
#         }
#       ]
#     }
#   }
# }
# '

# trying source field
# curl 'http://localhost:9200/test1/_search?pretty' -d '{
#   "aggs" : {},
#   "from" : 0,
#   "size" : 20,
#   "query" : {
#     "bool" : {
#       "must" : {
#         "match_all" : {}
#       }
#     }
#   },
#   "sort" : ["_score"],
#   "_source" : {
#     "includes" : [".*"]
#   }
# }'

# filtered by docs with annotation only
# curl 'http://localhost:9200/test1/_count?pretty' -d '{
#   "query" : {
#     "bool" : {
#       "must" : {
#         "match_all" : {}
#       },
#       "must" : {
#         "exists" : {
#           "field" : "annotations"
#         }
#       }
#     }
#   }
# }
# '

# search multiple text fields at once
# curl 'http://localhost:9200/test1/_count?pretty' -d '{
#   "query" : {
#     "query_string" : {
#       "query" : "Ed*th",
#       "fields" : ["annotations", "text"]
#     }
#   }
# }
# '

# search multiple text fields at once
# curl 'http://localhost:9200/test1/_search?pretty' -d '{
#   "from": 0,
#   "highlight": {
#     "fields": {
#       "text": {
#         "fragment_size": 100,
#         "number_of_fragments": 3
#       },
#       "annotations": {
#         "fragment_size":100,
#         "number_of_fragments": 3
#       }
#     }
#   },
#   "size": 20,
#   "query": {
#     "bool": {
#       "must": {
#         "query_string": {
#           "default_field": "text",
#           "query": "annotations:water"
#         }
#       },
#       "filter": [
#         {
#           "term": {
#             "collection": "cather"
#           }
#         }
#       ]
#     }
#   },
#   "sort": [
#     "_score"
#   ]
# }
# '

# search multiple queries at once
# curl 'http://localhost:9200/test1/_count?pretty' -d '{
#   "query" : {
#     "bool" : {
#       "should" : [
#         {
#           "query_string" : {
#             "query" : "Ed*th",
#             "fields" : ["annotations"]
#           }
#         },
#         {
#           "query_string": {
#             "query": "Ed*th",
#             "fields" : ["text"]
#           }
#         }
#       ]
#     }
#   }
# }
# '
