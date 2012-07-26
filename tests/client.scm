(use test http-client posix setup-api intarweb uri-common awful html-parser sxpath)

(define server-uri "http://localhost:8080")


(define (get path/vars)
  (let ((val (with-input-from-request
              (make-pathname server-uri path/vars)
              #f
              read-string)))
    (close-all-connections!)
    val))


(define (post path #!optional data)
  (let ((val (with-input-from-request
              (make-request
               uri: (uri-reference (make-pathname server-uri path))
               method: 'POST)
              data
              read-string)))
    (close-all-connections!)
    val))


(define (get-paste-link sxml)
  (let ((links ((sxpath '(// a)) sxml)))
    (let loop ((links links))
      (if (null? links)
          #f
          (let* ((link (car links))
                 (maybe-link (last link)))
            (if (and (string? maybe-link)
                     (string-prefix? "/paste?id=" maybe-link))
                maybe-link
                (loop (cdr links))))))))


(define (get-paste-from-html html)
  (let ((sxml (html->sxml html)))
    (last (car ((sxpath '(// tt)) sxml)))))


(define (paste-link->id link)
  (substring link 10))


(define response
  (html->sxml
   (post "/paste" '((nick  . "a nick")
                    (title . "a title")
                    (paste . "a paste")))))


(define paste-link #f)

(test-begin "pastiche")

(test-assert "Basic response sanity check"
             (pair? response))

(test-assert "Finding test paste link"
             (let ((link (get-paste-link response)))
               (set! paste-link link)
               (and (string? link)
                    (string-prefix? "/paste?id=" link))))

(test "Checking raw paste"
      "a paste"
      (get (string-append "/raw?id=" (paste-link->id paste-link) ";annotation=0")))


(test "Checking HTML paste (view paste)"
      "a paste"
      (get-paste-from-html (get paste-link)))

(test-end "pastiche")
