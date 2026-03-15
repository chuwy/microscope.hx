(require-builtin helix/components)

(require "helix/misc.scm")
(require "helix/commands.scm")
(require "input.scm")
(require "state.scm")

(provide microscope microscope-file-explorer)


(define MICROSCOPE-COMPONENT-NAME "microscope")


(define (microscope config)
  (define input (Input (box "") (box #f)))
  (define state (Microscope config (box input) (box (list)) (box 0) (box 1) (box #f)))

  (Microscope-refresh state)
  (push-component! (new-component! MICROSCOPE-COMPONENT-NAME
                                   state
                                   render-microscope
                                   (hash "handle_event" handle-microscope-event "cursor" get-microscope-cursor))))


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

  (microscope (Picker fetch show on-select)))


(define (string-repeat str n)
  (if (<= n 0)
      ""
      (string-append str (string-repeat str (- n 1)))))


(define (get-microscope-cursor state rect)
  (let* ([outer-area (calculate-outer-area rect)]
         [inner-area (calculate-input-area outer-area)]
         [cursor-position (unbox (Input-cursor (unbox (Microscope-input state))))])
         (position (area-y inner-area) (+ 1 (area-x inner-area) (if cursor-position cursor-position (string-length (Microscope-get-input state)))))))


(define (handle-microscope-event state event)
  (cond ([key-event-up? event] (begin (Microscope-prev state) event-result/consume))
        ([key-event-down? event] (begin (Microscope-next state) event-result/consume))
        ([key-event-escape? event] event-result/close)
        ([key-event-enter? event] (Microscope-select state))
        (else (process-press (Input-press (unbox (Microscope-input state)) event) state))))


;;@doc
;; Line's main purpose is to let your show function to render segments of different colors 
;; as well as to have an easy way to render right-hand side segments
(struct Line (lhs rhs))

(define (Line-lhs-append line pair)
  (let ([current-lhs (Line-lhs line)]
        [current-rhs (Line-rhs line)])
       (Line (append current-lhs (list pair)) current-rhs)))


(define (Line-render line frame x-start y-start width)
  (define (get-text section) (if (pair? section) (car section) section))

  (define x-current x-start)
  (define x-rhs (+ x-start width))

  (for-each (lambda (section)
                    (let ([text (get-text section)]
                          [style (if (pair? section) (cdr section) "ui.text")])
                         (frame-set-string!
                             frame
                             x-current
                             y-start
                             text
                             (theme-scope *helix.cx* style))
                         (set! x-current (+ x-current (string-length text)))))
            (Line-lhs line))

  ;; Pre-compute all right-hand starts
  (for-each (lambda (section)
                    (frame-set-string!
                             frame
                             (caddr section)
                             y-start
                             (car section)
                             (theme-scope *helix.cx* (cadr section))))
            (map (lambda (section)
                         (let* ([text (get-text section)]
                                [style (if (pair? section) (cdr section) "ui.text")]
                                ;; TODO: this currently works only for single section
                                [x-start (- x-rhs (string-length text) 2)])
                               (begin
                                  ; (notify (cons x-start text))
                                  (list text style x-start))))
                 (Line-rhs line))))


;;@doc
;; Process the result of Input-press
;; which can be either proper character input or cursor move
;; In case of a cursor move we don't call Microscope-refresh
(define (process-press result state)
  (case result
        ((changed) (Microscope-refresh state) event-result/consume)
        ((moved) event-result/consume)
        (else event-result/ignore)))


(define (calculate-outer-area rect)
  (let* ([screen-width (area-width rect)]
         [screen-height (area-height rect)]

         [outer-width (inexact->exact (round (* screen-width 0.50)))]
         [outer-height (inexact->exact (round (* screen-height 0.68)))]
         [outer-x (inexact->exact (round (/ (- screen-width outer-width) 2)))]
         [outer-y (inexact->exact (round (/ (- screen-height outer-height) 2)))])
         (area outer-x outer-y outer-width outer-height)))


(define (calculate-input-area outer-rect)
  (let* ([inner-width (- (area-width outer-rect) 2)]
         [inner-height 2]
         [inner-x (+ 1 (area-x outer-rect))]
         [inner-y (+ 1 (area-y outer-rect))])
         (area inner-x inner-y inner-width inner-height)))


(define (calculate-list-area outer-rect)
  (let* ([inner-width (- (area-width outer-rect) 2)]
         [inner-height (- (area-height outer-rect) 2)]
         [inner-x (+ 1 (area-x outer-rect))]
         [inner-y (+ 1 2 (area-y outer-rect))])
         (area inner-x inner-y inner-width inner-height)))


(define (render-microscope state rect frame)
  (define border-style (theme-scope *helix.cx* "info"))
  (define block (make-block (theme-scope *helix.cx* "ui.background") border-style "all" "rounded"))
  (define header-line (make-block (theme-scope *helix.cx* "ui.background") border-style "top" "plain"))

  (let* ([outer-area (calculate-outer-area rect)]
         [input-area (calculate-input-area outer-area)]
         [inner-area (calculate-list-area outer-area)]
         [header-area (area (area-x input-area) (+ (area-y input-area) 1) (area-width input-area) 1)]
         [slots (- (area-height inner-area) 2)])
         (begin
           (set-box! (Microscope-slots state) slots)
           (buffer/clear frame outer-area)
           (block/render frame outer-area block)
           (block/render frame header-area header-line)
           (render-microscope-input-line frame input-area state)
           (render-microscope-lines frame inner-area state))))


(define (render-microscope-input-line frame inner-area state)
  (define border-style (theme-scope *helix.cx* "info"))


  (define input (Microscope-get-input state))
  (frame-set-string!
    frame
    (+ 1 (area-x inner-area))
    (area-y inner-area)
    input
    (theme-scope *helix.cx* "ui.text")))


(define (render-microscope-lines frame inner-area state)
  (define selected-slot (Microscope-selected-slot state))
  (define width (- (area-width inner-area) 5))
  (map-index (lambda (idx line)
                     (when (< idx (length (Microscope-get-page state)))
                           (frame-set-string!
                             frame
                             (+ (area-x inner-area) 1)
                             (+ (area-y inner-area) idx)
                             (if (= idx selected-slot) "> " "  ")
                             (theme-scope *helix.cx* "ui.text.focus"))

                           (Line-render line
                                        frame
                                        (+ (area-x inner-area) 3)
                                        (+ (area-y inner-area) idx)
                                        width)))
             (Microscope-render-items state width)))


(define (map-index func lst)
  (define index (box 0))
  (map (lambda (elem)
               (define index-val (unbox index))
               (set-box! index (+ index-val 1))
               (func index-val elem)) lst))
