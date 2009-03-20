;; TODO
;; * Det saknas macro-use
;; * Den kompilerar inte om dependencies n�r det beh�vs (pga
;;   makro-expansion)
;; * St�d f�r att kompilera till annan mapp
;; * L�gg till s� att man kan importera utan att
;;   importera alla symboler till namespacet
;; * G�r en funktion som s�ker och visar vilka moduler som
;;   definierar en viss symbol
;; * L�gg till st�d f�r att detektera namespace-konflikter
;; * B�ttre saker f�r att styra visibility
;; * do, time, parameterize form f�r hygiensystemet
;; * (let-syntax ((blah ...)) (define-syntax ...)) fungerar inte
;;   n�r det inre makrot anv�nder blah.
;; * Jag borde n�stan helt kasta expr.scm

;; Design limitations
;; * Just nu om man har en fil som kr�ver kompilering kommer
;;   den att kompileras n�r den (use)as, oavsett om det redan
;;   �r en kompilering ig�ng. Detta kraschar Gambit.
;;     Compile-all-modules g�r runt denna begr�nsning, s� s�vitt
;;   jag vet visar sig detta endast n�r man har en fil som
;;   kr�ver kompilering som (use)ar en annan fil som kr�ver
;;   kompilering, d� (use) av den f�rsta filen alltid kommer
;;   krascha om inte den andra redan �r kompilerad.
;; * #!key parameters �r om�jligt att implementera hygien till.

;; Feature requests
;; * Something to be able to work around #!key parameter hygiene

;; Filer som anv�nder namespaces
;; * lib/typecheck
;; * lib/profiler
;; * lib/dbi
;; * siim/lib
;; * db/atom-db

;; black hole

(##namespace ("build#"))

(##include "~~/lib/gambit#.scm")

(declare (standard-bindings)
	 (extended-bindings)
	 (block))

;; Utility functions. There because I can't include libraries from here
(##include "util.scm")

;; Library for handling Gambit source objects
(##include "expr.scm")

;; The syntax closures implementation
(##include "hygiene.scm")

;; The syntax-rules implementation
(##include "syntax-rules.scm")

;; The module system core
(##include "module.scm")

;; Some utilities, for instance module-compile/deps!
(##include "extras.scm")


;; Add the hooks =)

(define build-hook (make-parameter (lambda (src compiling?) src)))

(let ((hook (lambda (compiling?)
              (lambda (src)
                (let ((ret (expr:deep-fixup
                            ((build-hook)
                             (expand-macro src)
                             compiling?))))
                  ;; Useful when debugging
                  ;; (pp (expr*:strip-locationinfo ret))
                  ret)))))
  (set! ##expand-source (hook #f))
  (set! c#expand-source (hook #t)))

