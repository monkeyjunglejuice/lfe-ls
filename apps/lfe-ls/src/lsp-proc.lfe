(defmodule lsp-proc
  (export
   (process-input 2)))

(include-lib "apps/lfe-ls/include/utils.lfe")
(include-lib "apps/lfe-ls/include/lsp-model.lfe")

(defun %req-parse-error () -32700)
(defun %req-invalid-request-error () -32600)

(defun process-input (input state)
  (case (try
            (let ((json-input (ljson:decode input)))
              (logger:debug "json-input: ~p" `(,json-input))
              (case json-input
                (`(#(#"jsonrpc" #"2.0")
                   #(#"id" ,req-id)
                   #(#"method" ,req-method)
                   #(#"params" ,req-params))
                 (%process-method req-id req-method req-params state))
                (`(#(#"jsonrpc" #"2.0")
                   #(#"method" ,req-method)
                   #(#"params" ,req-params))
                 (%process-method 'null req-method req-params state))
                (_
                 (logger:warning "Invalid lsp header!")
                 `#(#(reply ,(%make-error-response 'null
                                                   (%req-invalid-request-error)
                                                   #"Invalid LSP header!"))
                    ,state))))
          (catch
            ((tuple type value stacktrace)
             (progn
               (logger:warning "Error on json operation: ~p, type: ~p, value: ~p"
                               `(,stacktrace ,type ,value))
               `#(#(reply ,(%make-error-response 'null
                                                 (%req-parse-error)
                                                 #"Error on parsing json!"))
                  ,state)))))
    (`#(#(,code ,response) ,state) `#(#(,code ,(ljson:encode response)) ,state))))

(defun %process-method (id method params state)
  "This function is the main lsp 'method' dispatcher.
It returns:

`(tuple (tuple code response) new-state)`
where `code' is either `reply' or `noreply' indicating that the response has to be sent back to the requester or not. LSP notifications don't require reply but requests do.
`response' is the generated lsp response for the received request.
"
  (case method
    (#"initialize"
     (case (%on-initialize-req id params)
       (`#(reply ,response)
        `#(#(reply ,response) ,(set-lsp-state-initialized state 'true)))))
    (#"initialized"
     `#(,(%on-initialized-req id params) ,state))
    (#"test-success"
     `#(#(reply ,(%make-result-response id 'true)) ,state))
    (_
     `#(#(reply ,(%make-error-response id
                                       (%req-invalid-request-error)
                                       (concat-binary #"Method not supported: '"
                                                      (concat-binary method #"'!"))))
        ,state))))

(defun %on-initialize-req (id params)
  `#(reply ,(%make-result-response id (%make-initialize-result params))))

(defun %on-initialized-req (id params)
  `#(noreply null))

(defun %make-result-response (id result)
  `(#(#"id" ,id) #(#"result" ,result)))

(defun %make-error-response (id code err-msg)
  `(#(#"id" ,id) #(#"error" (#(#"code" ,code)
                             #(#"message" ,err-msg)))))

(defun %make-initialize-result (req-params)
  `(,(%make-capabilities)
    #(#"serverInfo" (#(#"name" #"lfe-ls")))))

(defun %make-capabilities ()
  #(#"capabilities" (#(#"textDocument"
                       (#(#"completion"
                          (#(#"dynamicRegistration" false))))))))
