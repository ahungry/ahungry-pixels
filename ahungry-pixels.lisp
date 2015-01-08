;; ahungry-pixels - Pixel animator for HTML5/JS written in Common Lisp
;; Copyright (C) 2013 Matthew Carter
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;; 
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;;; ahungry-pixels.lisp

(in-package #:ahungry-pixels)

;;; "ahungry-pixels" goes here. Hacks and glory await!

(setf *js-string-delimiter* #\")
(setf *ps-print-pretty* t)

;; Any of the parenscript macros can sit here
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro+ps event-listener (object event trigger)
    "Applies a proper event-listener to whatever we want"
    `(chain ,object (add-event-listener ,event ,trigger t)))
  (defmacro+ps style-setter (val default &optional extra)
    "Set up to create the if blocks that set oldStyles and style"
    `(when (not (equal (@ old-styles ,val) ,default))
       (setf (@ style ,val) ,(if extra `(+ ,default ,extra) default)
             (@ old-styles ,val) ,default))))

;; Lazily hold different js aspects in a hash table
(defparameter *js* (make-hash-table :test 'equal))

(defmacro defjs (name args &rest fn)
  "Set up a parenscript block for later rendering"
  `(setf (gethash (string ',name) *js*)
         (ps (defun ,name ,args ,@fn))))

(defjs $$ (div)
  "Selector for document items"
  (chain document (get-element-by-id div)))

(defjs init (&optional blub canvas)
  "Window init wants to pass a load, so ignore blub"
  (setf *canvas* (if canvas canvas ($$ "canvas"))
        (@ *canvas* style background-color) "#444"
        (@ *canvas* height) (* *block-size* *blocks*)
        (@ *canvas* width) (* *block-size* *blocks*)
        *ctx* (chain *canvas* (get-context "2d")))

  (unless canvas
    (setf (aref *frames* *active-frame*) [])
    (dotimes (y *blocks*)
      (setf (aref *frames* *active-frame* y) [])
      (dotimes (x *blocks*)
        (setf (aref *frames* *active-frame* y x) "rgba(0,0,0,0)"))))

  (set-timeout init-frame 200)
  (clear)

  nil)

(defjs init-once ()
  "Things that we only want to do once"
  (init)
  
  (setf (@ ($$ "animation") style height) (+ (* *block-size*
                                                *blocks*) "px"))
  (setf (@ ($$ "animation") style width) (+ (* *block-size*
                                               *blocks*) "px"))
  ;; Add event listeners
  (event-listener window "mousedown" click)
  (event-listener window "mouseup"   unclick)
  (event-listener window "mousemove" moving)

  (event-listener ($$ "fps"         ) "change"    update-fps)
  (event-listener ($$ "hex-color"   ) "change"    hex-to-rgb)
  (event-listener ($$ "colorpicker" ) "mousemove" click)
  (event-listener ($$ "clear"       ) "mousedown" moving)
  (event-listener ($$ "save"        ) "mousedown" moving)
  (event-listener ($$ "new-frame"   ) "mousedown" new-frame)
  (event-listener ($$ "clone-frame" ) "mousedown" clone-frame)
  (event-listener ($$ "play"        ) "mousedown" toggle-play)

  (setf *settings* (list
                    ($$ "bp-color-R")
                    ($$ "bp-color-G")
                    ($$ "bp-color-B")
                    ($$ "bp-color-A")
                    ($$ "bp-cursor-size")))

  (loop for i in *settings*
     do (event-listener i "change" set-settings))

  (set-timeout animation-updater 1)
  (set-timeout animation 1)
  (set-settings)
  (set-interval (λλ α → (set-settings)) 500)
  (set-interval (λλ α → (animation-updater)) 1000))

(defjs init-frame ()
  "Paint canvas based on frame data"
  (dotimes (y *blocks*)
    (dotimes (x *blocks*)
      (let ((color (aref *frames* *active-frame* y x)))
        (setf (@ *ctx* fill-style) color)
        (chain *ctx* (fill-rect (* x *block-size*)
                                (* y *block-size*)
                                (* 1 *block-size*)
                                (* 1 *block-size*)))))))

(defjs in-range (c min max)
  "Check if a value is in range"
  (cond ((or (is-na-n (@ c value))
             (< (@ c value length) 0)
             (< (@ c value) min))
         (setf (@ c value) min))
        ((> (@ c value) max)
         (setf (@ c value) max))
        (t (@ c value))))

(defjs hex-to-rgb ()
  "Convert hex value to rgb"
  (let ((hex (@ ($$ "hex-color") value)))
    (loop for i from 0 to 2
       do (progn
            (let ((ss (chain hex (substr (1+ (* 2 i)) 2))))
              (setf (@ (aref *settings* i) value)
                    (parse-int ss 16)))))
    (set-settings)))

(defjs update-fps ()
  "Grab the FPS"
  (setf *fps* (in-range ($$ "fps") 1 30)))

(defjs set-settings ()
  "Set the relevant settings/params"
  (let ((color "rgba("))
    (loop for i from 0 to 3
       do (progn
            (let ((v (in-range (aref *settings* i)
                               0 (if (< i 3) 255 100))))
              (setf color (+ color (if (< i 3) v (parse-float (/ v 100))))
                    color (+ color (if (< i 3) "," ")"))))))
    (setf *cursor-size* (in-range (aref *settings* 4) 1 10))
    (update-fps)
    (setf *color* color)))

(defjs clear ()
  "Clear the canvas"
  (setf (@ *ctx* fill-style) "#ffffff")
  (chain *ctx* (fill-rect 0 0
                          (* *block-size* *blocks*)
                          (* *block-size* *blocks*))))

(defjs draw-block (x y &optional size)
  "Draw a single block at cursor point"
  (unless (or (> x (* *block-size* *blocks*))
              (> y (* *block-size* *blocks*)))
    (let ((bx (ash (/ x *block-size*) 0))
          (by (ash (/ y *block-size*) 0))
          (size (or size *cursor-size*)))
      (setf (@ *ctx* fill-style) *color*)
      (setf (aref *frames* *active-frame* by bx) *color*)
      (chain *ctx* (fill-rect (* bx *block-size*)
                              (* by *block-size*)
                              (* *block-size* size)
                              (* *block-size* size))))))

(defjs unclick ()
  (setf *mousedown* nil))

(defjs click ()
  (setf *mousedown* t)
  (when *mousedown* (draw-block x y)))

(defjs moving (e)
  (setf x (- (@ e page-x) (@ canvas offset-left))
        y (- (@ e page-y) (@ canvas offset-top)))
  (if (or (> x (* *block-size* *blocks*))
          (> y (* *block-size* *blocks*)))
      (setf *mousedown* nil))
  (when *mousedown* (draw-block x y)))

(defjs save ()
  (setf png-save-data (chain canvas (to-data-url "image/png"))))

(defjs animation (animation-array)
  "Run the main animation for our drawing"
  (if (or (not *play*)
          (not animation-array)
          (> 1 (length animation-array)))
      (set-timeout (λλ α → (animation (chain (aref *images*) (slice 0)))) (/ 1000 *fps*))
      (let* ((image-data (chain animation-array (shift)))
             (img (chain document (create-element "img"))))
        (setf (@ img src) image-data)
        ;; This doesn't seem to be needed but could be useful maybe
        ;;(setf (chain ($$ "animation") inner-h-t-m-l) "")
        (chain ($$ "animation") (append-child img))
        (set-timeout (λλ α → (animation animation-array))
                     (/ 1000 *fps*)))))

(defjs animation-updater ()
  (setf (aref *images*  *active-frame*)
        (chain *canvas* (to-data-u-r-l "image/png"))))

(defjs new-frame ()
  "Grab active-frame and clone it"
  (let ((old-frame []))
    (dotimes (y *blocks*)
      (setf (aref old-frame y) [])
      (dotimes (x *blocks*)
        (setf (aref old-frame y x) "rgba(0,0,0,0)")))
    (setf (aref *images*  *active-frame*)
          (chain *canvas* (to-data-u-r-l "image/png")))
    (incf *frame-counter*)
    (setf *active-frame* *frame-counter*)
    (setf (aref *frames* *active-frame*)
          (chain old-frame (slice 0))))
  (let ((new-frame (chain ($$ "canvas") (clone-node))))
    (chain document body (append-child new-frame))
    (init nil new-frame)))

(defjs clone-frame ()
  "Grab active-frame and clone it"
  (let ((old-frame (aref *frames* *active-frame*)))
    (setf (aref *images*  *active-frame*)
          (chain *canvas* (to-data-u-r-l "image/png")))
    (incf *frame-counter*)
    (setf *active-frame* *frame-counter*)
    (setf (aref *frames* *active-frame*)
          (chain old-frame (slice 0))))
  (let ((new-frame (chain ($$ "canvas") (clone-node))))
    (chain document body (append-child new-frame))
    (init nil new-frame)))

(defjs toggle-play ()
  "Toggle playing the animation or not"
  (if *play*
      (setf *play* nil
            (@ ($$ "play") value) "play")
      (setf *play* t
            (@ ($$ "play") value) "pause")))

(defun web-js ()
  "Relevant web js"
  (let ((js ""))
    (setf js 
          (ps
            (chain window (add-event-listener "load" init-once false))
            (defvar *mousedown* nil)
            (defvar *block-size* 10)
            (defvar *blocks* 32)
            (defvar x 0)
            (defvar y 0)
            (defvar *active-frame* 0)
            (defvar *settings* [])
            (defvar *cursor-size* 10)
            (defvar *color* "black")
            (defvar *frame-counter* 0)
            (defvar *play* t)
            (defvar *images* [])
            (defvar *fps* 5)
            (defvar *frames* [])))
    (maphash (lambda (k v) ;; Print out all our defjs that was stored earlier
               (declare (ignore k))
               (setf js (format nil "~a~%~a" js v))) *js*) js))

(defun web-css ()
  "The relevant CSS"
  (css-lite:css

    (("#animation")
     (:position "fixed" :top "0px" :left "0px" :background "#666"
                :padding "30px" :margin "20px" :height "320px" :width "320px"
                :border "1px solid #000" :box-shadow "3px 3px 6px #000")
     (("img") (:position "absolute")))

    (("#controls")
     (:position "fixed" :top "0px" :right "0px" :background "#ccc"
                :color "#000"
                :height "100%" :border-left "2px solid #000" :width "200px")
     (("input") (:width "100%" :font-size "9px"))

     ((".button") (:width "100%" :background "#000" :display "block"
                          :padding "3px" :color "#fff" :border "2px solid #000"
                          :text-align "left" :border "0" :border-radius "10px"))
     ((".button:hover") (:background "#999" :cursor "pointer" :border "2px solid lime"))
     (("label") (:display "block" :clear "both" :padding "6px"
                          :text-align "left" :font-size "9px")))

    ((".canvas")
     (:opacity ".7"
               :box-shadow "3px 3px 6px #000" :border "1px solid #000"
               :margin "20px"
               :display "block" :position "fixed" :top "0px" :right "200px"))

    (("#pallette")
     (:position "fixed" :top "0px" :right "0px"))

    ((".color")
     (:height "20px" :width "20px"
              :border-radius "10px"
              :margin "3px"
              :border "2px solid #000"))

    ((".pixel-editor")
     (:position "fixed" :top "0px" :left "0px"
                :opacity ".4"
                :width "500px"
                :height "500px"))

    ((".pixel")
     (:height "9px"
              :background "transparent"
              :display "inline-block"
              :font-size "1px"
              :margin-right "-1px"
              :margin-bottom "-1px"
              :width "9px"
              :border "1px solid #bbb"))))

(defun web-html ()
  "Provide a pixel editor for creating sprite animations"
  (with-html-output-to-string (s)
    (htm (:html
          (:head
           (:title "Pixel Editor")
           (:meta :charset "utf-8")
           (:link :rel "stylesheet" :href "ahungry-pixels.css" :type "text/css")
           (:script :type "text/javascript" :src "ahungry-pixels.js")
           (:body
            (:div :id "animation")
            (:canvas :id "canvas" :class "canvas")
            (:div :id "controls"
                  (:label "Pick:"  (:input :type "text" :id "colorpicker" :value "0"))
                  (:label "Red:"   (:input :type "text" :id "bp-color-R" :value "0"))
                  (:label "Green:" (:input :type "text" :id "bp-color-G" :value "0"))
                  (:label "Blue:"  (:input :type "text" :id "bp-color-B" :value "0"))
                  (:label "Alpha:" (:input :type "text" :id "bp-color-A" :value "100"))
                  (:label "Hex:"   (:input :type "text" :id "hex-color"  :value "#000000"))
                  (:label "Size:"  (:input :type "text" :id "bp-cursor-size"  :value "5"))
                  (:label "FPS:"   (:input :type "text" :id "fps"  :value "5"))
                  (:label (:input :class "button" :type "button" :id "new-frame"  :value "new frame"))
                  (:label (:input :class "button" :type "button" :id "clone-frame"  :value "clone frame"))
                  (:label (:input :class "button" :type "button" :id "play"  :value "pause"))
                  (:label (:input :class "button" :type "button" :id "save"  :value "save"))
                  (:label (:input :class "button" :type "button" :id "clear"  :value "clear"))
                  )
            ))))))

(in-package #:cl-user)

(defparameter *toot* (make-instance 'hunchentoot:easy-acceptor
                                    :port 4141
                                    :message-log-destination nil
                                    :access-log-destination nil))
(setf (hunchentoot:acceptor-document-root *toot*) #P"~/src/lisp/ahungry-pixels/www/")
(hunchentoot:start *toot*)

(hunchentoot:define-easy-handler (html :uri "/") ()
  (setf (hunchentoot:content-type*) "text/html")
  (ahungry-pixels:web-html))

(hunchentoot:define-easy-handler (js :uri "/ahungry-pixels.js") ()
  (setf (hunchentoot:content-type*) "text/js")
  (ahungry-pixels:web-js))

(hunchentoot:define-easy-handler (css :uri "/ahungry-pixels.css") ()
  (setf (hunchentoot:content-type*) "text/css")
  (ahungry-pixels:web-css))
