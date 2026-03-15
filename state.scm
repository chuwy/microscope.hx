(require-builtin helix/components)

(require "input.scm")

(provide Picker
         Microscope Microscope-input Microscope-items Microscope-selected Microscope-refresh Microscope-selected-slot Microscope-slots
         Microscope-prev Microscope-next Microscope-get-input Microscope-select Microscope-render-items Microscope-get-page)


(struct Microscope (
        ;; Immutable picker's config provided by user
        config
        ;; The state of input field
        input
        ;; All items grabbed with Picker-fetch
        items
        ;; Global index of a selected item
        selected
        ;; Number of slots to display
        slots
        ;; User-defined mutable state, preserved between Picker-on-select calls
        state))


;;@doc
;; The main structure used to create reusable pickers.
(struct Picker
  (fetch     ; function: (string? any/c -> list?) fetches items based on input field text
   show      ; function: (any/c -> string?) renders an item as a string
   on-select))  ; function: (any/c -> void?) callback invoked when user hits Return


;;@doc
;; Get the content of input field
(define (Microscope-get-input mcs)
  (unbox (Input-text (unbox (Microscope-input mcs)))))


;;@doc
;; Run a fetch function defined in user-provided Picker
(define (Microscope-fetch mcs query state)
  ((Picker-fetch (Microscope-config mcs)) query state))


(define (Microscope-select mcs)
  (let* ([selected (Microscope-selected-item mcs)]
         [callback (Picker-on-select (Microscope-config mcs))]
         [result (callback selected (unbox (Microscope-state mcs)))]
         [new-state (cdr result)]
         [event-result (car result)])
        (begin
          (set-box! (Microscope-state mcs) new-state)
          (Input-reset (unbox (Microscope-input mcs)))
          ; event-result/consume means we're not closing the picker and keep interacting with it
          (when (eq? event-result event-result/consume)
                (Microscope-refresh mcs))
          event-result)))


;;@doc
;; Get string representations of items to render
(define (Microscope-render-items mcs width)
  (map (lambda (item) ((Picker-show (Microscope-config mcs)) item width))
       (Microscope-get-page mcs)))


(define (Microscope-selected-item mcs)
  (list-ref (Microscope-get-page mcs) (Microscope-selected-slot mcs)))


;; items is all items collected with fetch
;; fetch gets executed every time we type something (so items recalculated)
;; selected is index in items
;; page defines a slice of items
;; selected-slot that defines an item selected on a current page, it depends on selected, page and items

(define (Microscope-next mcs)
  (let ([current-slot (+ 1 (Microscope-selected-slot mcs))]
        [current (+ 1 (unbox (Microscope-selected mcs)))]
        [total (length (unbox (Microscope-items mcs)))]
        [page-size (unbox (Microscope-slots mcs))])
    (cond
      ([and (< current-slot page-size) (< current total)]
       (set-box! (Microscope-selected mcs) current))
      ([and (>= current-slot page-size) (< current total)]
       (set-box! (Microscope-selected mcs) current))
      (else void))))


(define (Microscope-prev mcs)
  (let ([previous-slot (Microscope-selected-slot mcs)]
        [previous-idx (unbox (Microscope-selected mcs))]
        [page-size (unbox (Microscope-slots mcs))])
    (cond
      ([and (= previous-slot 0) (= previous-idx 0)] void)
      ([and (= previous-slot 0) (> previous-idx 0)]
       (set-box! (Microscope-selected mcs) (- previous-idx 1)))
      ([and (> previous-slot 0)]
       (set-box! (Microscope-selected mcs) (- previous-idx 1)))
      (else void))))


(define (Microscope-get-page mcs)
  (let* ([slots (unbox (Microscope-slots mcs))]
         [since (* (Microscope-page-num mcs) slots)])
        (slice (unbox (Microscope-items mcs)) since slots)))


(define (Microscope-page-num mcs)
  (let ([idx (unbox (Microscope-selected mcs))]
        [slots (unbox (Microscope-slots mcs))])
       (quotient idx slots)))


(define (Microscope-selected-slot mcs)
  (let ([idx (unbox (Microscope-selected mcs))]
        [slots (unbox (Microscope-slots mcs))])
       (remainder idx slots)))

;;@doc
;; Fetch all items and render them
;; Gets called when
;; * Microscope first initialized
;; * User changed the content of input field
;; * When fetch callback returned consume instead of close
(define (Microscope-refresh mcs)
  (let* ([query (Microscope-get-input mcs)]
         [state (unbox (Microscope-state mcs))])
        (set-box! (Microscope-selected mcs) 0)
        (set-box! (Microscope-items mcs) (Microscope-fetch mcs query state))))


(define (slice l offset n)
  (let loop ((lst l) (pos 0) (acc '()))
    (cond
     ((null? lst) 
      (reverse acc))  ; Return what we have if list ends early
     ((>= pos (+ offset n))
      (reverse acc))  ; Collected enough elements
     ((>= pos offset)
      (loop (cdr lst) (+ pos 1) (cons (car lst) acc)))  ; Collect element
     (else
      (loop (cdr lst) (+ pos 1) acc)))))  ; Skip until offset
