;;; keychain-environment.el --- Loads keychain environment variables into emacs
 
;; Copyright (C) 2008,2009 Paul Tipper
 
;; Author:  Paul Tipper <bluefoo at googlemail dot com>
;; Keywords: keychain, ssh
;; Created: 18 Dec 2008

;; Version: 1.0.1

;; This file is not part of GNU Emacs.
 
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary: 
;; 
;; Designed for use with Keychain, see:
;; (http://www.gentoo.org/proj/en/keychain/) a tool for loading the
;; SSH Agent and keeping it running and accessible on a machine for
;; longer than a single login seession.
;; 
;; This library loads the file "$HOME/.keychain/$HOSTNAME-sh" and parses
;; it for the SSH_AUTH_SOCK and SSH_AUTH_PID variables, placing these into the
;; environment of Emacs.
;;
;; This is useful for situations where you are running Emacs under X, not
;; directly from a terminal, and its inheriting its environment from the
;; window manager, which doesn't have these variables as you started keychain
;; after you logged in (say as part of your .bashrc)
;;
;; The function (refresh-keychain-environment) can also be run at any time
;; these variables change.

;;; Installation:
;; Put the file in your load-path then use:
;; 
;;   (require 'keychain-environment)
;;   (eval-after-load "keychain-environment" '(refresh-keychain-environment))
;;
;; If you want to customise the location of the keychain file then use this:
;;
;;   (setq keychain-environment-file "~/path-to-file")
 
;;; History:
;; 2008-12-18 Initial development.
;; 2009-02-25 Fixed bug with system-name being evaluated to the full hostname

;;; Code: 

(if (not (boundp 'keychain-environment-file))
    (defvar keychain-environment-file  (concat (getenv "HOME")
                                               "/.keychain/" 
                                               (car (split-string system-name 
                                                                  "\\." 
                                                                  t))
                                               "-sh")
      "Stores the location of the keychain file to load.  Normally
found in the '$HOME/.keychain' directory and called
'$HOSTNAME-sh'."))


;; Really there should be an easier method of doing this surely?
(if (not (fboundp 'read-file))
    (defun read-file (filename)
      "Takes a filename, reads the data from it and returns it as a string"
      
      (let* ((real-filename (expand-file-name filename))
             (visited (find-buffer-visiting real-filename))
             (orig-buffer (current-buffer))
             (buf (find-file-noselect real-filename))
             (data (save-excursion
                     (set-buffer buf)
                     (let ((data (buffer-substring-no-properties (point-min) 
                                                                 (point-max))))
                       (set-buffer orig-buffer)
                       data))))
        
        ;; Only kill the buffer if we didn't have a copy when we started
        (if (null visited)
            (kill-buffer buf))
        
        ;; And return the data.
        data)))

(defun refresh-keychain-environment ()
  "Reads the keychain file for /bin/sh and sets the SSH_AUTH_SOCK
and SSH_AGENT_PID variables into the environment and returns them
as a list."
  (interactive)
  (let* ((data (read-file keychain-environment-file))
         (auth-sock (progn 
                      (string-match "SSH_AUTH_SOCK=\\(.*?\\);" data)
                      (match-string 1 data)))
         (auth-pid (progn
                     (string-match "SSH_AGENT_PID=\\([0-9]*\\)?;" data)
                     (match-string 1 data))))
    (setenv "SSH_AUTH_SOCK" auth-sock)
    (setenv "SSH_AUTH_PID" auth-pid)
    (list auth-sock auth-pid)))


(provide 'keychain-environment)
