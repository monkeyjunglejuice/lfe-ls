
(include-lib "lsp-model.lfe")

(defrecord ls-state
  (device 'nil)
  (lsp-state (make-lsp-state)))
