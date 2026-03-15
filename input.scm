(require-builtin helix/components)

(provide Input Input-text Input-cursor Input-press Input-reset)

;;@doc
;; Data structure holding a string for an input field as well as a cursor position in it
(struct Input (text cursor))


;;@doc
;; React to a keyboard event intended for an input field
;; pressing a printable character or moving a cursor with left/right arrows
;; Anything that is not intended for the input field is handled via handle-microscope-event
(define (Input-press input event)
  (let ([text (unbox (Input-text input))]
        [cursor (unbox (Input-cursor input))])
    (cond
        ((key-event-char event)
         (let* ([char (string (key-event-char event))]
                [text-next (if cursor (insert-char text char cursor) (string-append text char))])
               (begin
                 (set-box! (Input-text input) text-next)
                 (when cursor (set-box! (Input-cursor input) (+ 1 cursor)))
                 'changed)))
        ((and (key-event-left? event) cursor (> cursor 0)) (begin (set-box! (Input-cursor input) (- cursor 1)) 'moved))
        ((and (key-event-left? event) (not cursor)) (begin (set-box! (Input-cursor input) (- (string-length text) 1)) 'moved))
        ((and (key-event-right? event) cursor (< cursor (string-length text))) (begin (set-box! (Input-cursor input) (+ cursor 1)) 'moved))
        ((and (key-event-backspace? event)) (begin (Input-backspace input) 'changed))
        (else 'ignore))))


(define (Input-reset input)
  (set-box! (Input-text input) "")
  (set-box! (Input-cursor input) 0))


(define (Input-backspace input)
  (let ([text (unbox (Input-text input))]
        [cursor (unbox (Input-cursor input))])
       (set-box! (Input-text input) (backspace-char text cursor))
       (when (> cursor 0)
             (set-box! (Input-cursor input) (- cursor 1)))))


;;@doc
;; Insert a substring into a string at a position 
(define (insert-char str sub pos)
  (if (or (< pos 0) (> pos (string-length str)))
      (error "insert-char: position out of bounds")
      (let ((str-len (string-length str)))
        (cond ((= pos 0)
               (string-append sub str))
              ((= pos str-len)
               (string-append str sub))
              (else
               (string-append
                (substring str 0 pos)
                sub
                (substring str pos str-len)))))))


(define (backspace-char str pos)
  (let* ([len (string-length str)]
         [idx (if pos pos len)])   ; pos can be #f if we never moved the cursor
    (cond
     ((= len 0) str)
     ((= idx len) (substring str 0 (- idx 1)))
     ((< idx 0) (error (string-append "backspace-char: position cannot be negative. idx: " (string idx))))
     ((> idx len) (error (string-append "backspace-char: position out of bounds. idx: " (string idx) " len: " (string len))))
     (else
      (string-append
       (substring str 0 idx)
       (substring str (+ idx 1) len))))))

