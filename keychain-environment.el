;;; keychain-environment.el --- Loads keychain environment variables into emacs
 
;; Copyright (C) 2008,2009 Paul Tipper
;;               2010 Michael "cofi" Markert
;; Time-stamp: <2010-08-10 03:42:38 cofi>
 
;; Author:  Paul Tipper <bluefoo at googlemail dot com>
;;          Michael Markert <markert.michael at googlemail dot com>
;; Keywords: keychain, ssh
;; Created: 18 Dec 2008

;; Version: 1.2

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
;; This library loads the file "$HOME/.keychain/$HOSTNAME-sh" and parses it for
;; the SSH_AUTH_SOCK, SSH_AUTH_PID and GPG_AGENT_INFO variables, placing these
;; into the environment of Emacs.
;;
;; This is useful for situations where you are running Emacs under X, not
;; directly from a terminal, and its inheriting its environment from the
;; window manager, which doesn't have these variables as you started keychain
;; after you logged in (say as part of your .bashrc)
;;
;; The function (keychain/refresh) can also be run at any time these variables
;; change.

;;; Installation:
;; Put the file in your load-path then use:
;; 
;;   (require 'keychain-environment)
;;   (eval-after-load "keychain-environment" '(keychain/refresh))
;;
;; If you want to customise the location of the keychain file then use this:
;;
;;   (setq keychain/ssh-file "~/path-to-file")
;;   (setq keychain/gpg-file "~/path-to-file")
 
;;; History:
;; 2008-12-18 Initial development.
;; 2009-02-25 Fixed bug with system-name being evaluated to the full hostname
;; 2010-07-27 Added GPG_AGENT support.
;; 2010-08-10 Changed namingscheme.

;;; Code: 

(defconst keychain/dir (concat (getenv "HOME") "/.keychain/" )
  "Location of keychain directory. Normally `$HOME/.keychain'")

(let ((hostname (car (split-string system-name "\\." t)))
      (ssh-postfix "-sh")
      (gpg-postfix "-sh-gpg"))
  (if (not (boundp 'keychain/ssh-file))
      (defvar keychain/ssh-file  (concat keychain/dir
                                         hostname
                                         ssh-postfix)
        "Stores the location of the keychain ssh file to load.
Normally found in the `keychain/dir' and called '$HOSTNAME-sh'."))
  (if (not (boundp 'keychain/gpg-file))
      (defvar keychain/gpg-file  (concat keychain/dir
                                         hostname
                                         gpg-postfix)
        "Stores the location of the keychain gpg file to load.
Normally found in the `keychain/dir' and called '$HOSTNAME-sh-gpg'.")))

(if (not (fboundp 'keychain/read-file))
    (defun keychain/read-file (filename)
      "Takes a filename, reads the data from it and returns it as a string"
      (let ((real-filename (expand-file-name filename)))
        (with-temp-buffer
          (insert-file-contents real-filename)
          (buffer-string)))))

(defun keychain/refresh ()
  "Reads the keychain file for /bin/sh and sets the SSH_AUTH_SOCK, SSH_AGENT_PID
and GPG_AGENT variables into the environment and returns them as a list."
  (interactive)
  (let* ((ssh-data (keychain/read-file keychain/ssh-file))
         (gpg-data (keychain/read-file keychain/gpg-file))
         (auth-sock (progn 
                      (string-match "SSH_AUTH_SOCK=\\(.*?\\);" ssh-data)
                      (match-string 1 ssh-data)))
         (agent-pid (progn
                     (string-match "SSH_AGENT_PID=\\([0-9]*\\)?;" ssh-data)
                     (match-string 1 ssh-data)))
         (gpg-agent (progn
                      (string-match "GPG_AGENT_INFO=\\(.*?\\);" gpg-data)
                      (match-string 1 gpg-data)))
         )
    (setenv "SSH_AUTH_SOCK" auth-sock)
    (setenv "SSH_AGENT_PID" agent-pid)
    (setenv "GPG_AGENT_INFO" gpg-agent)
    (list auth-sock agent-pid gpg-agent)))

(defalias 'refresh-keychain-environment 'keychain/refresh)

(provide 'keychain-environment)
