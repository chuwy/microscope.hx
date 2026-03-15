(require-builtin helix/components)

(provide calculate-input-area calculate-list-area calculate-outer-area)


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



