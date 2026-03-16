(provide file-previewer)


(define (file-previewer path)
  (if (is-dir? path)
      (map file-name (read-dir path))
      (call-with-exception-handler (lambda (err) (list (to-string err)))
                                   (lambda () (call-with-input-file path
                                                                    (lambda (port)
                                                                      (let loop ((lines '()))
                                                                        (let ((line (read-line port)))
                                                                          (if (eof-object? line)
                                                                              (reverse lines)
                                                                              (loop (cons line lines)))))))))))
