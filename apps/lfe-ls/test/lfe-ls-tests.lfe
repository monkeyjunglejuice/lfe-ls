(defmodule lfe-ls-tests
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

;; your test code here

(deftest create-lfe-ls
  (let ((`#(ok ,pid) (gen_server:start 'lfe-ls '#(other) '())))
    (io:format "~p~n" `(,pid))
    (gen_server:stop pid)))

(deftest test-receive-package
  (let* ((`#(ok ,pid) (gen_server:start 'lfe-ls '#(other) '()))
         (response (gen_server:call pid `#(received #"Content-Length: 5\r\n\r\nHello"))))
    (io:format "resp: ~p~n" `(,response))
    (is-match `#(ok #(state nil #(req 5 5 #"Hello"))) response)
    (gen_server:stop pid)))
