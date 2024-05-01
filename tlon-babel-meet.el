;;; tlon-babel-meet.el --- Manage Tlön meetings -*- lexical-binding: t -*-

;; Copyright (C) 2024

;; Author: Pablo Stafforini
;; Homepage: https://github.com/tlon-team/tlon-babel
;; Version: 0.1

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Manage Tlön meetings.

;;; Code:

(require 'org)
(require 'tlon-babel-forg)

;;;; Functions

(defun tlon-babel-create-or-visit-meeting-issue (&optional person-or-group)
  ""
  (interactive)
  (let ((person-or-group (or person-or-group (tlon-babel-prompt-for-all-other-users t))))
    (if (string= person-or-group "group")
	(tlon-babel-create-or-visit-group-meeting-issue)
      (tlon-babel-create-or-visit-individual-meeting-issue person-or-group))))

(defun tlon-babel-create-or-visit-individual-meeting-issue (person &optional date)
  "Create or visit issue for a meeting with PERSON on DATE."
  (interactive (list (tlon-babel-prompt-for-all-other-users)))
  (let* ((date (or date (org-read-date)))
	 (dir (tlon-babel-get-meeting-repo person user-full-name)))
    (tlon-babel-create-or-visit-meeting-issue-date date dir)))

(defun tlon-babel-create-or-visit-group-meeting-issue (&optional date)
  "Create or visit issue for a group meeting on DATE."
  (interactive)
  (let* ((date (or date (org-read-date)))
	 (dir (tlon-babel-repo-lookup :dir :name "meetings-group")))
    (tlon-babel-create-or-visit-meeting-issue-date date dir)))

(defun tlon-babel-create-or-visit-meeting-issue-date (date dir)
  "Create or visit issue in DIR for a meeting on DATE."
  (if-let ((issue (tlon-babel-issue-lookup date dir)))
      (forge-visit-issue issue)
    (tlon-babel-create-and-visit-issue date dir)))

;; TODO: generate the next three functions with function
;;;###autoload
(defun tlon-babel-create-or-visit-meeting-issue-leo-pablo ()
  "Create or visit issue for a meeting with Leo and Pablo."
  (interactive)
  (let ((person (pcase user-full-name
		  ("Pablo Stafforini" "Leonardo Picón")
		  ("Leonardo Picón" "Pablo Stafforini")
		  (_ (user-error "This command is only for Leo and Pablo meetings")))))
    (tlon-babel-create-or-visit-individual-meeting-issue person (org-read-date))))

;;;###autoload
(defun tlon-babel-create-or-visit-meeting-issue-fede-pablo ()
  "Create or visit issue for a meeting with Fede and Pablo."
  (interactive)
  (let ((person (pcase user-full-name
		  ("Pablo Stafforini" "Federico Stafforini")
		  ("Federico Stafforini" "Pablo Stafforini")
		  (_ (user-error "This command is only for Fede and Pablo meetings")))))
    (tlon-babel-create-or-visit-individual-meeting-issue person (org-read-date))))

;;;###autoload
(defun tlon-babel-create-or-visit-meeting-issue-fede-leo ()
  "Create or visit issue for a meeting with Fede and Leo."
  (interactive)
  (let ((person (pcase user-full-name
		  ("Federico Stafforini" "Leonardo Picón")
		  ("Leonardo Picón" "Federico Stafforini")
		  (_ (user-error "This command is only for Leo and Fede meetings")))))
    (tlon-babel-create-or-visit-individual-meeting-issue person (org-read-date))))

(defun tlon-babel-prompt-for-all-other-users (&optional group)
  "Ask the user to select from a list of all users except himself.
If GROUP is non-nil, include the \"group\" option in the prompt."
  (completing-read "Person: "
		   (let ((people
			  (cl-remove-if (lambda (user)
					  (string= user user-full-name))
					(tlon-babel-user-lookup-all :name))))
		     (if group
			 (append people '("group"))
		       people))))

;; TODO: create `tlon-babel-issue-lookup-all', analogous to `tlon-babel-lookup-all'
(defun tlon-babel-get-meeting-repo (participant1 participant2)
  "Get directory of meeting repo for PARTICIPANT1 and PARTICIPANT2."
  (catch 'found
    (dolist (repo tlon-babel-repos)
      (when (and
	     (eq 'meetings (plist-get repo :subtype))
	     (member participant1 (plist-get repo :participants))
	     (member participant2 (plist-get repo :participants)))
	(throw 'found (plist-get repo :dir))))))

(defun tlon-babel-create-and-visit-issue (title dir)
  "Create an issue with TITLE in DIR and visit it."
  (with-temp-buffer
    (cd dir)
    (when (forge-current-repository)
      (tlon-babel-create-issue title dir)
      (forge-pull)
      (while (not (tlon-babel-issue-lookup title dir))
	(sleep-for 0.1))
      (forge-visit-issue (tlon-babel-issue-lookup title dir))
      (format "*forge: %s %s*" (oref (forge-current-repository) slug) (oref (forge-current-topic) slug)))))

;; TODO: generalize to all possible meetings
(defun tlon-babel-discuss-issue-in-meeting ()
  "Create a reminder to discuss the current issue in a meeting.
We should try to follow the rule of avoiding prolonged discussions in the issue
tracker, and instead conduct these discussions in person or over a call. This
function tried to be a nudge in that direction."
  (interactive)
  (unless (derived-mode-p 'forge-issue-mode)
    (user-error "This command can only be invoked in Forge issue buffers"))
  (let (backlink)
    (save-excursion
      (let* ((repo-name (oref (forge-current-repository) name))
	     (issue-number (oref (forge-current-issue) number))
	     (link (format "tlon-team/%s#%s" repo-name issue-number)))
	(switch-to-buffer (tlon-babel-create-or-visit-meeting-issue))
	(let* ((repo-name (oref (forge-current-repository) name))
	       (issue-number (oref (forge-current-issue) number)))
	  (setq backlink (format "tlon-team/%s#%s" repo-name issue-number))
	  (goto-char (point-max))
	  (forward-line -1)
	  (forge-edit-post)
	  (while (not (derived-mode-p 'forge-post-mode))
	    (sleep-for 0.1))
	  (goto-char (point-max))
	  (insert (format "- Discutir %s." link))
	  (forge-post-submit))))
    (forge-create-post)
    (while (not (derived-mode-p 'forge-post-mode))
      (sleep-for 0.1))
    (insert (format "A discutir en %s." backlink))
    (forge-post-submit)))


;;;;; Menu

;;;###autoload (autoload 'tlon-babel-meet-menu "tlon-babel-meet.el" nil t)
(transient-define-prefix tlon-babel-meet-menu ()
  "`meet' menu."
  ["Meetings"
   ("l p" "Leo-Pablo"                  tlon-babel-create-or-visit-meeting-issue-leo-pablo)
   ("f p" "Fede-Pablo"                 tlon-babel-create-or-visit-meeting-issue-fede-pablo)
   ("f l" "Fede-Leo"                   tlon-babel-create-or-visit-meeting-issue-fede-leo)
   ("g"   "group"                      tlon-babel-create-or-visit-group-meeting-issue)
   ("i"    "discuss issue in meeting"  tlon-babel-discuss-issue-in-meeting)])

(provide 'tlon-babel-meet)
;;; tlon-babel-meet.el ends here

