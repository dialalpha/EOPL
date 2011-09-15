(load "/Users/ruben/Dropbox/EOPL/src/interps/r5rs.scm")
(load "/Users/ruben/Dropbox/EOPL/src/interps/define-datatype.scm")
(load "/Users/ruben/Dropbox/EOPL/src/interps/2-3-2.scm") ;environments
(load "/Users/ruben/Dropbox/EOPL/src/interps/sllgen.scm")

;Let's switch now to implementing the interpreter using sllgen to generate
;the frontend

(define scanner-spec-3-13
  '((white-sp
      (whitespace) skip)
    (comment
      ("%" (arbno (not #\newline))) skip)
    (identifier
      (letter (arbno (or letter digit "?"))) symbol)
    (number
      (digit (arbno digit)) number)))

(define grammar-3-13
  '((program
      (expression)
      a-program)
    (expression
      (number)
      lit-exp)
    (expression
      (identifier)
      var-exp)
    (expression
      (primitive "(" (separated-list expression ",") ")")
      primapp-exp)
    (expression
      ("if" expression "then" expression "else" expression)
      if-exp)
    (expression
      ("unpack" (arbno identifier) "=" expression "in" expression)
      unpack-exp)
    (primitive
      ("+")
      add-prim)
    (primitive
      ("-")
      substract-prim)
    (primitive
      ("*")
      mult-prim)
    (primitive
      ("add1")
      incr-prim)
    (primitive
      ("sub1")
      decr-prim)
    (primitive
      ("equal?")
      equal-prim)
    (primitive
      ("zero?")
      zero-prim)
    (primitive
      ("greater?")
      greater-prim)
    (primitive
      ("less?")
      less-prim)
    (primitive
      ("cons")
      cons-prim)
    (primitive
      ("car")
      car-prim)
    (primitive
      ("cdr")
      cdr-prim)
    (primitive
      ("list")
      list-prim)
    (primitive
      ("eq?")
      eq-prim)))

(define scan&parse
  (sllgen:make-string-parser
    scanner-spec-3-13
    grammar-3-13))

(sllgen:make-define-datatypes scanner-spec-3-13 grammar-3-13)

(define run
  (lambda (string)
    (eval-program
      (scan&parse string))))

;helpers
(define true-value?
  (lambda (x)
    (not (zero? x))))


; the interpreter
(define eval-program
  (lambda (pgm)
    (cases program pgm
           (a-program (body)
                      (eval-expression body (init-env))))))

(define eval-expression
  (lambda (exp env)
    (cases expression exp
           (lit-exp (datum) datum)
           (var-exp (id) (apply-env env id))
           (if-exp (test-exp true-exp false-exp)
                   (if (true-value? (eval-expression test-exp env))
                       (eval-expression true-exp env)
                       (eval-expression false-exp env)))
           (unpack-exp (ids exp body)
                       (let ((lst (eval-expression exp env)))
                         (if (= (length ids) (length lst))
                             (eval-expression body (extend-env ids lst env))
                             (eopl:error 'eval-expression
                                         "Expected ~s elements in the lst expression, got ~s"
                                         (length ids)
                                         (length lst)))))
           (primapp-exp (prim rands)
                        (let ((args (eval-rands rands env)))
                          (apply-primitive prim args))))))

(define eval-rands
  (lambda (rands env)
    (map (lambda (x) (eval-rand x env)) rands)))

(define eval-rand
  (lambda (rand env)
    (eval-expression rand env)))

(define apply-primitive
  (lambda (prim args)
    (cases primitive prim
           (add-prim () (+ (car args) (cadr args)))
           (substract-prim () (- (car args) (cadr args)))
           (mult-prim () (* (car args) (cadr args)))
           (incr-prim () (+ (car args) 1))
           (decr-prim () (- (car args) 1))
           (equal-prim () (if (= (car args) (cadr args)) 1 0))
           (zero-prim () (if (zero? (car args)) 1 0))
           (greater-prim () (if (> (car args) (cadr args)) 1 0))
           (less-prim () (if (< (car args) (cadr args)) 1 0))
           (cons-prim () (cons (car args) (cadr args)))
           (car-prim () (car (car args)))
           (cdr-prim () (cdr args))
           (list-prim () args)
           (eq-prim () (if (eq? (car args) (cadr args)) 1 0)))))

(define init-env
  (lambda ()
    (extend-env
      '(i v x emptylist)
      '(1 5 10 ())
      (empty-env))))


;Tests
;> (run "unpack x y z = list(1,2,3) in +(x,+(y,z))")
;6
;> (run "unpack x y z = list(1,2) in +(x,+(y, z))")
;Error reported by eval-expression:
;Expected 3 elements in the lst expression, got 2