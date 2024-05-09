;;; tlon-dispatch.el --- Transient dispatchers -*- lexical-binding: t -*-

;; Copyright (C) 2024

;; Author: Pablo Stafforini
;; Homepage: https://github.com/tlon-team/tlon
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

;;  Transient dispatchers.

;;; Code:

(require 'tlon-core)

;;;; Functions

;; maybe move this to `simple-extras', since they are universal functions for reading symbols, numbers
(defun tlon-transient-read-symbol-choice (prompt choices)
  "Return a list of CHOICES with PROMPT to be used as an `infix' reader function."
  (let* ((input (completing-read prompt (mapcar 'symbol-name choices))))
    (intern input)))

(defun tlon-transient-read-number-choice (prompt choices)
  "Return a list of CHOICES with PROMPT to be used as an `infix' reader function."
  (let* ((input (completing-read prompt (mapcar 'number-to-string choices))))
    (string-to-number input)))

(defun tlon-transient-read-string-choice (prompt choices)
  "Return a list of CHOICES with PROMPT to be used as an `infix' reader function."
  (let* ((input (completing-read prompt choices)))
    (substring-no-properties input)))

;;;;; Main menu

;; TODO: add flag to set translation language, similar to Magit dispatch
;;;###autoload (autoload 'tlon-dispatch "tlon-dispatch" nil t)
(transient-define-prefix tlon-dispatch ()
  "Dispatch a `tlon' command."
  :info-manual "(tlon) Main menu"
  [["Main menu"
    "Submenus"
    ("a" "AI"                             tlon-ai-menu)
    ("c" "clock"                          tlon-clock-menu)
    ("e" "edit data"                      tlon-edit-data-menu)
    ("f" "files"                          tlon-files-menu)
    ("i" "api"                            tlon-api-menu)
    ("j" "jobs"                           tlon-jobs-menu)
    ("k" "markdown"                       tlon-md-menu)
    ("H-m" "meet"                         tlon-meet-menu)
    ("r" "repos"                          tlon-repos-menu)
    ("s" "search"                         tlon-search-menu)
    ("y" "forg"                           tlon-forg-menu)]
   ["""Browse repo"
    ("d" "in Dired"                       tlon-dired-repo-menu)
    ("m" "in Magit"                       tlon-magit-repo-menu)]
   [""""
    ("." "notifications"                  forge-list-notifications)]])

;;;;; Browse repo in Magit

(defmacro tlon-generate-magit-browse-commands (name dir)
  "Generate commands for browsing repo named NAME in Magit.
DIR is the directory where the repo is stored."
  `(defun ,(intern (format "tlon-magit-browse-%s" name)) ()
     ,(format "Browse the %s repository in Magit." name)
     (interactive)
     (magit-status ,dir)))

(dolist (repo tlon-repos)
  (eval `(tlon-generate-magit-browse-commands
	  ,(plist-get repo :abbrev)
	  ,(plist-get repo :dir))))

;;;###autoload (autoload 'tlon-magit-repo-menu "tlon-dispatch" nil t)
(transient-define-prefix tlon-magit-repo-menu ()
  "Browse a Tlön repo in Magit."
  [["Tlon"
    ("t c" "tlon-content"                 tlon-magit-browse-tlon-content)
    ("t f" "tlon-front"                   tlon-magit-browse-tlon-front)
    ("t d" "tlon-docs"                    tlon-magit-browse-docs)]
   ["Babel"
    ("b c" "babel-core"                   tlon-magit-browse-babel-core)
    ("b r" "babel-refs"                   tlon-magit-browse-babel-refs)
    ("b i" "babel-issues"                 tlon-magit-browse-babel-issues)
    ""
    ("b d" "babel-de"                     tlon-magit-browse-babel-de)
    ("b s" "babel-es"                     tlon-magit-browse-babel-es)
    ("b r" "babel-fr"                     tlon-magit-browse-babel-fr)
    ("b t" "babel-it"                     tlon-magit-browse-babel-it)]
   ["Uqbar"
    ("q i" "uqbar-issues"                 tlon-magit-browse-uqbar-issues)
    ("q f" "uqbar-front"                  tlon-magit-browse-uqbar-front)
    ("q a" "uqbar-api"                    tlon-magit-browse-uqbar-api)
    ""
    ("q n" "uqbar-en"                     tlon-magit-browse-uqbar-en)
    ("q s" "uqbar-es"                     tlon-magit-browse-uqbar-es)
    ("q r" "uqbar-fr"                     tlon-magit-browse-uqbar-fr)
    ("q t" "uqbar-it"                     tlon-magit-browse-uqbar-it)]
   ["utilitarianism"
    ("u n" "utilitarianism-en"            tlon-magit-browse-utilitarianism-en)
    ("u s" "utilitarianism-es"            tlon-magit-browse-utilitarianism-es)
    ""
    "Essays on Longtermism"
    ("e n" "essays-en"                    tlon-magit-browse-essays-en)
    ("e s" "essays-es"                    tlon-magit-browse-essays-es)
    ""
    "EA International"
    ("i i" "ea.international"             tlon-magit-browse-ea-international)]
   ["La Bisagra"
    ("s a" "bisagra-api"                  tlon-magit-browse-bisagra-api)
    ("s f" "bisagra-front"                tlon-magit-browse-bisagra-front)
    ("s c" "bisagra-content"              tlon-magit-browse-bisagra-content)
    ""
    "Boletín"
    ("a a" "boletin"                      tlon-magit-browse-boletin)]
   ["EA News"
    ("n i" "ean-issues"                   tlon-magit-browse-ean-issues)
    ("n f" "ean-front"                    tlon-magit-browse-ean-front)
    ("n a" "ean-api"                      tlon-magit-browse-ean-api)]
   ["Meetings"
    ("m l p" "Leo-Pablo"                  tlon-magit-browse-meetings-leo-pablo)
    ("m f p" "Fede-Pablo"                 tlon-magit-browse-meetings-fede-pablo)
    ("m f l" "Fede-Leo"                   tlon-magit-browse-meetings-fede-leo)
    ("m g" "group"                        tlon-magit-browse-meetings-group)
    ""
    "Clock"
    ("c l" "Leo"                          tlon-magit-browse-clock-leo)
    ("c f" "Fede"                         tlon-magit-browse-clock-fede)
    ("c p" "Pablo"                        tlon-magit-browse-clock-pablo)]])

;;;;; Browse repo in Dired

(defmacro tlon-generate-dired-browse-commands (name dir)
  "Generate commands for browsing repo named NAME.
DIR is the directory where the repo is stored."
  `(defun ,(intern (format "tlon-dired-browse-%s" name)) ()
     ,(format "Browse the %s repository in Dired." name)
     (interactive)
     (dired ,dir)))

(dolist (repo tlon-repos)
  (eval `(tlon-generate-dired-browse-commands
	  ,(plist-get repo :abbrev)
	  ,(plist-get repo :dir))))

;;;###autoload (autoload 'tlon-dired-repo-menu "tlon-dispatch" nil t)
(transient-define-prefix tlon-dired-repo-menu ()
  "Browse a Tlön repo in Dired."
  [["Tlon"
    ("t c" "tlon-content"                 tlon-dired-browse-tlon-content)
    ("t f" "tlon-front"                   tlon-dired-browse-tlon-front)
    ("t d" "tlon-docs"                    tlon-dired-browse-docs)]
   ["Babel"
    ("b c" "babel-core"                   tlon-dired-browse-babel-core)
    ("b i" "babel-issues"                 tlon-dired-browse-babel-issues)
    ("b r" "babel-refs"                   tlon-dired-browse-babel-refs)
    ""
    ("b d" "babel-de"                     tlon-dired-browse-babel-de)
    ("b s" "babel-es"                     tlon-dired-browse-babel-es)
    ("b r" "babel-fr"                     tlon-dired-browse-babel-fr)
    ("b t" "babel-it"                     tlon-dired-browse-babel-it)]
   ["Uqbar"
    ("q i" "uqbar-issues"                 tlon-dired-browse-uqbar-issues)
    ("q f" "uqbar-front"                  tlon-dired-browse-uqbar-front)
    ("q a" "uqbar-api"                    tlon-dired-browse-uqbar-api)
    ""
    ("q n" "uqbar-en"                     tlon-dired-browse-uqbar-en)
    ("q s" "uqbar-es"                     tlon-dired-browse-uqbar-es)
    ("q r" "uqbar-fr"                     tlon-dired-browse-uqbar-fr)
    ("q t" "uqbar-it"                     tlon-dired-browse-uqbar-it)]
   ["utilitarianism"
    ("u n" "utilitarianism-en"            tlon-dired-browse-utilitarianism-en)
    ("u s" "utilitarianism-es"            tlon-dired-browse-utilitarianism-es)
    ""
    "Essays on Longtermism"
    ("e n" "essays-en"                    tlon-dired-browse-essays-en)
    ("e s" "essays-es"                    tlon-dired-browse-essays-es)
    ""
    "EA International"
    ("i i" "ea-international"             tlon-dired-browse-ea-international)]
   ["La Bisagra"
    ("s a" "bisagra-api"                  tlon-dired-browse-bisagra-api)
    ("s f" "bisagra-front"                tlon-dired-browse-bisagra-front)
    ("s c" "bisagra-content"              tlon-dired-browse-bisagra-content)
    ""
    "Boletín"
    ("a a" "boletin"                      tlon-dired-browse-boletin)]
   ["EA News"
    ("n i" "ean-issues"                   tlon-dired-browse-ean-issues)
    ("n f" "ean-front"                    tlon-dired-browse-ean-front)
    ("n a" "ean-api"                      tlon-dired-browse-ean-api)]
   ["Meetings"
    ("m l p" "Leo-Pablo"                  tlon-dired-browse-meetings-leo-pablo)
    ("m f p" "Fede-Pablo"                 tlon-dired-browse-meetings-fede-pablo)
    ("m f l" "Fede-Leo"                   tlon-dired-browse-meetings-fede-leo)
    ("m g" "group"                        tlon-dired-browse-meetings-group)
    ""
    "Clock"
    ("c l" "Leo"                          tlon-dired-browse-clock-leo)
    ("c f" "Fede"                         tlon-dired-browse-clock-fede)
    ("c p" "Pablo"                        tlon-dired-browse-clock-pablo)]])

;;;;; Open file in repo

(defmacro tlon-generate-open-file-in-repo-commands (repo)
  "Generate commands to open file in REPO."
  (let* ((repo-name (tlon-repo-lookup :abbrev :dir repo))
	 (command-name (intern (concat "tlon-open-file-in-" repo-name))))
    `(defun ,command-name ()
       ,(format "Interactively open a file from a list of all files in `%s'" repo-name)
       (interactive)
       (tlon-find-file-in-repo ,repo))))

(dolist (repo (tlon-repo-lookup-all :dir))
  (eval `(tlon-generate-open-file-in-repo-commands ,repo)))

;;;###autoload (autoload 'tlon-find-file-in-repo-menu "tlon-dispatch" nil t)
(transient-define-prefix tlon-find-file-in-repo-menu ()
  "Interactively open a file from a Tlön repo."
  [["Tlon"
    ("t c" "tlon-content"                   tlon-open-file-in-tlon-content)
    ("t f" "tlon-front"                   tlon-open-file-in-tlon-front)
    ("t d" "tlon-docs"                    tlon-open-file-in-docs)]
   ["Babel"
    ("b c" "babel-core"                   tlon-open-file-in-babel-core)
    ("b r" "babel-refs"                   tlon-open-file-in-babel-refs)
    ("b i" "babel-issues"                 tlon-open-file-in-babel-issues)
    ""
    ("b d" "babel-de"                     tlon-open-file-in-babel-de)
    ("b s" "babel-es"                     tlon-open-file-in-babel-es)
    ("b r" "babel-fr"                     tlon-open-file-in-babel-fr)
    ("b t" "babel-it"                     tlon-open-file-in-babel-it)]
   ["Uqbar"
    ("q i" "uqbar-issues"                 tlon-open-file-in-uqbar-issues)
    ("q f" "uqbar-front"                  tlon-open-file-in-uqbar-front)
    ("q a" "uqbar-api"                    tlon-open-file-in-uqbar-api)
    ""
    ("q n" "uqbar-en"                     tlon-open-file-in-uqbar-en)
    ("q s" "uqbar-es"                     tlon-open-file-in-uqbar-es)
    ("q r" "uqbar-fr"                     tlon-open-file-in-uqbar-fr)
    ("q t" "uqbar-it"                     tlon-open-file-in-uqbar-it)]
   ["utilitarianism"
    ("u n" "utilitarianism-en"            tlon-open-file-in-utilitarianism-en)
    ("u s" "utilitarianism-es"            tlon-open-file-in-utilitarianism-es)
    ""
    "Essays on Longtermism"
    ("e n" "essays-en"                    tlon-open-file-in-essays-en)
    ("e s" "essays-es"                    tlon-open-file-in-essays-es)
    ""
    "EA International"
    ("i " "ea-international"              tlon-open-file-in-ea-international)]
   ["La Bisagra"
    ("s a" "bisagra-dev"                  tlon-open-file-in-bisagra-api)
    ("s f" "bisagra-front"                tlon-open-file-in-bisagra-front)
    ("s c" "bisagra-content"              tlon-open-file-in-bisagra-content)
    ""
    "Boletín"
    ("a a" "boletin"                      tlon-open-file-in-boletin)]
   ["EA News"
    ("n i" "ean-issues"                   tlon-open-file-in-ean-issues)
    ("n f" "ean-front"                    tlon-open-file-in-ean-front)
    ("n a" "ean-api"                      tlon-open-file-in-ean-api)]
   ["Meetings"
    ("m l p" "Leo-Pablo"                  tlon-open-file-in-meetings-leo-pablo)
    ("m f p" "Fede-Pablo"                 tlon-open-file-in-meetings-fede-pablo)
    ("m f l" "Fede-Leo"                   tlon-open-file-in-meetings-fede-leo)
    ("m g" "group"                        tlon-open-file-in-meetings-group)
    ""
    "Clock"
    ("c l" "Leo"                          tlon-open-file-in-clock-leo)
    ("c f" "Fede"                         tlon-open-file-in-clock-fede)
    ("c p" "Pablo"                        tlon-open-file-in-clock-pablo)]])

;;;;; Files menu

;;;###autoload (autoload 'tlon-files-menu "tlon-dispatch" nil t)
(transient-define-prefix tlon-files-menu ()
  "Files menu."
  :info-manual "(tlon) Files"
  [["Find"
    ("c" "in current repo"                 tlon-find-file-in-repo)
    ("o" "in another repo"                 tlon-find-file-in-repo-menu)
    ("a" "across repos"                    tlon-open-file-across-repos)]
   ["Open counterpart"
    ("f" "current window"                  tlon-open-counterpart-dwim)
    ("H-f" "other window"                  tlon-open-counterpart-in-other-window-dwim)]
   [""
    ("b" "Browse externally"               tlon-browse-file)]
   ["Issue"
    ("i" "file"                            tlon-open-forge-file)
    ("I" "counterpart"                     tlon-open-forge-counterpart)]
   ["Version control"
    ("l" "log"                             magit-log-buffer-file)
    ("d" "diffs since last user change"    tlon-log-buffer-latest-user-commit)
    ("e" "ediff with last user change"     tlon-log-buffer-latest-user-commit-ediff)]])

;;;;; Search menu

;;;###autoload (autoload 'tlon-search-menu "tlon-dispatch" nil t)
(transient-define-prefix tlon-search-menu ()
  "Search menu."
  ["Search"
   ("s" "multi"                        tlon-search-multi)
   ("c" "commits"                      tlon-search-commits)
   ("d" "commit-diffs"                 tlon-search-commit-diffs)
   ("f" "files"                        tlon-search-files)
   ("i" "issues"                       tlon-search-issues)
   ("t" "translation"                  tlon-search-for-translation)])

;;;;; Data files menu

;;;###autoload (autoload 'tlon-edit-data-menu "tlon-dispatch" nil t)
(transient-define-prefix tlon-edit-data-menu ()
  "Data files menu."
  ["Edit data files"
   "Glossary"
   ("g" "edit glossary"              tlon-edit-glossary)
   ("G" "extract glossary"           tlon-extract-glossary)
   "TTS"
   ("a" "abbreviations"              tlon-edit-abbreviations)
   ("A" "file-local abbreviations"   tlon-add-file-local-abbreviation)
   ("r" "replacements"               tlon-edit-phonetic-replacements)
   ("R" "file-local replacements"    tlon-add-file-local-replacement)
   ("t" "phonetic transcriptions"    tlon-edit-phonetic-transcriptions)])

(provide 'tlon-dispatch)
;;; tlon-dispatch.el ends here