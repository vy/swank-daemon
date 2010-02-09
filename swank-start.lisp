;;; swank-start.lisp - Start a new swank server with respect to given
;;;                    SWANK_PORT, SWANK_CODING_SYSTEM and
;;;                    SWANK_PID_FILE environment variables.

;;; Copyright (c) 2010, Volkan YAZICI <volkan.yazici@gmail.com>
;;; All rights reserved.
;;;   
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;;   
;;; - Redistributions of source code must retain the above copyright notice,
;;;   this list of conditions and the following disclaimer.
;;;   
;;; - Redistributions in binary form must reproduce the above copyright notice,
;;;   this list of conditions and the following disclaimer in the documentation
;;;   and/or other materials provided with the distribution.
;;;   
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

#-ccl
(defun getenv (name &optional default)
  #+cmu
  (let ((x (assoc name ext:*environment-list* :test #'string=)))
    (if x (cdr x) default))
  #-cmu
  (or
   #+allegro (sys:getenv name)
   #+clisp (ext:getenv name)
   #+ecl (si:getenv name)
   #+sbcl (sb-unix::posix-getenv name)
   #+lispworks (lispworks:environment-variable name)
   default))

;; Validate passed arguments.
(dolist (var '("STY" "SWANK_PID_FILE" "SWANK_PORT" "SWANK_CODING_SYSTEM"))
  (unless (getenv var)
    (error "Missing environment variable!" var)))

;; Report PID information.
(with-open-file (out (getenv "SWANK_PID_FILE")
                 :direction :output
                 :if-exists :supersede)
  (write-string (getenv "STY") out))

;; Load ASDF and swank.
(require :asdf)
(asdf:oos 'asdf:load-op :swank)

;; Communication will be established through a single stream.
(setf swank:*use-dedicated-output-stream* nil)

;; Fire up a fresh swank server.
(swank:create-server :port (parse-integer (getenv "SWANK_PORT"))
		     :coding-system (getenv "SWANK_CODING_SYSTEM")
		     :dont-close t)
