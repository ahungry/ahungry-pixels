;;;; ahungry-pixels.asd

(asdf:defsystem #:ahungry-pixels
  :serial t
  :description "Pixel animator for HTML5/JS written in Common Lisp"
  :author "Matthew Carter <m@ahungry.com>"
  :license "AGPLv3"
  :depends-on (#:cl-who
               #:parenscript
               #:css-lite
               #:hunchentoot
               #:cl-ppcre
               #:glyphs)
  :components ((:file "package")
               (:file "ahungry-pixels")))

