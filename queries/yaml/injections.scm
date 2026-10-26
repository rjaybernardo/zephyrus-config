; extends

; ESPHome: highlight `lambda:` bodies as C++.
;   lambda: |-
;     return id(x).state > 20;
(block_mapping_pair
  key: (flow_node) @_key
  (#any-of? @_key "lambda" "condition_lambda")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "cpp")
    (#offset! @injection.content 0 1 0 0)))

;   lambda: 'return x == "1234";'
(block_mapping_pair
  key: (flow_node) @_key
  (#any-of? @_key "lambda" "condition_lambda")
  value: (flow_node
    [(single_quote_scalar) (double_quote_scalar)] @injection.content
    (#set! injection.language "cpp")
    (#offset! @injection.content 0 1 0 -1)))
