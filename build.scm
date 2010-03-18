;; TODO
;; * implementera include
;; * Den kompilerar inte om dependencies n�r det beh�vs (pga
;;   makro-expansion)
;; * St�d f�r att kompilera till annan mapp
;; * G�r en funktion som s�ker och visar vilka moduler som
;;   definierar en viss symbol
;; * L�gg till st�d f�r att detektera namespace-konflikter
;; * Jag borde n�stan helt kasta expr.scm
;; * Kolla m�jligheten att implementera kompatibilitetslager f�r R6RS
;; * �ndra s� att inget som kr�vs f�r runtime i build �r exporterat by
;;   default i moduler. D�remot ska allt vara importerat by default i
;;   REPLen.
;;
;; Enkel TODO
;; * Implementera lib
;; * K�llkodsplatser
;; * do, time, parameterize form f�r hygiensystemet

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

(##namespace ("module#"))

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

;; The lib (fetching remote modules) implementation
(##include "lib.scm")

;; Some utilities, for instance module-compile/deps!
(##include "extras.scm")



;;;; ---------- Hack for configuration ----------

;; Variables declared here are used all over the place.

;; Configuration directives
(define *compiler-options* '())
(define *compiler-cc-options* "")
(define *compiler-ld-options-prelude* "")
(define *compiler-ld-options* "")

;;(set! *compiler-options* '(debug))
;;(set! *compiler-cc-options* "-I/usr/local/BerkeleyDB.4.7/include")
;;(set! *compiler-ld-options-prelude* "-L/usr/local/BerkeleyDB.4.7/lib")

(set! *module-resolvers*
      `((here . ,current-module-resolver)
        (module . ,(make-singleton-module-resolver
                    module-module-loader))
        (lib . ,lib-module-resolver)
        (std . ,(package-module-resolver "~~lib/modules/std"))))




;; ---------- Add the hooks =) ----------

(let ((hook (lambda (compiling?)
              (lambda (src)
                (let ((ret (expr:deep-fixup
                            (expand-macro src))))
                  ;; Useful when debugging
                  ;; (pp (expr*:strip-locationinfo ret))
                  ret)))))
  (set! ##expand-source (hook #f))
  (set! c#expand-source (hook #t)))

(##vector-set!
 (##thread-repl-channel-get! (current-thread))
 6
 (lambda (channel level depth)
   (let ((mod (environment-module (top-environment))))
     (if mod
         (begin
           (print ((loader-module-name (module-loader mod)) mod))
           (if (##fixnum.< 0 level)
               (print "/")))))
   (##repl-channel-ports-read-command channel level depth)))

