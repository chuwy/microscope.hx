(require-builtin helix/components)

(require "helix/commands.scm")
(require "microscope.scm")
(require "previewer.scm")

(provide microscope-file-explorer)

;; Example file picker
(define (microscope-file-explorer)
  (define (on-select selected state)
    (define selected-full (canonicalize-path selected))
    (cond [(eq? selected "..")
           ;; At the moment we hit '..' - we have the last current dir in the state
           (cons event-result/consume (if state (parent-name state) selected-full))]
          [(is-dir? selected)
           (cons event-result/consume selected-full)]
          [else
           (open selected)
           (cons event-result/close selected-full)]))

  (define (fetch query state)
    (define dirs (read-dir (or state ".")))
    (filter (lambda (item) (string-contains? (file-name item) query)) (cons ".." dirs)))

  (define (show path width)
    (let
      ([lhs (cond
              ((eq? path "..") (cons ".." "ui.text.directory") )
              ((is-dir? path) (cons (string-append (file-name path) "/") "ui.text.directory") )
              (else (cons (file-name path) "ui.text") ))]
       [rhs (if (is-dir? path) (cons (to-string (length (read-dir path))) "ui.text") "")])

      (Line (list lhs) (list rhs))))


  (microscope (Picker fetch show on-select file-previewer)))

