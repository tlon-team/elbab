;;; tlon-import.el --- Import functions for the Babel project -*- lexical-binding: t -*-

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

;; Import functions for the Babel project.

;;; Code:

(require 'request)
(require 'tlon-cleanup)
(require 'tlon-fix)

;;;; Variables

;;;;; EAF API

(defconst tlon-import-eaf-api-url
  "https://forum.effectivealtruism.org/graphql"
  "URL for the EAF GraphQL API endpoint.")

(defconst tlon-import-eaf-objects
  '(post tag)
  "List of entities supported by the EAF GraphQL API.")

;;;;; EAF validation

(defconst tlon-import-eaf-url-regexp
  "forum\\.effectivealtruism\\.org/"
  "Regular expression for validating EAF URLs.")

(defconst tlon-import-eaf-article-id-regexp
  "\\([[:alnum:]]\\{17\\}\\)"
  "Regular expression for validating post IDs.")

(defconst tlon-import-eaf-tag-slug-regexp
  "\\([[:alnum:]-]*\\)"
  "Regular expression for validating tag slugs.")

;;;;; Pandoc

(defconst tlon-pandoc-convert-from-file
  "pandoc -s '%s' -t markdown -o '%s'"
  "Command to convert from HTML file to Markdown.")

(defconst tlon-pandoc-convert-from-url
  "pandoc -s -r html '%s' -o '%s'"
  "Command to convert from URL to Markdown.")

;;;;; Executables

(defvar tlon-pdf2md
  (file-name-concat paths-dir-external-repos "pdf2md/lib/pdf2md-cli.js")
  "Path to `pdf2md-cli.js' executable.")

(defvar tlon-pdftotext
  "pdftotext"
  "Path to `pdftotext' executable.")

;;;; Functions

;;;;; General import

(declare-function simple-extras-string-is-url-p "simple-extras")
(defun tlon-import-document (&optional identifier title)
  "Import a document with IDENTIFIER.
IDENTIFIER can be a URL or a PDF file path.

This command also imports EA Forum posts and tags. TITLE optionally specifies
the title of the document to be imported."
  (interactive)
  (let ((identifier (or identifier (read-string "Identifier (URL or PDF path): "))))
    (if (simple-extras-string-is-url-p identifier)
	(tlon-import-html identifier title)
      (tlon-import-pdf (expand-file-name identifier)))))

(defun tlon-import-html (url &optional title)
  "Import the HTML in URL and convert it to Markdown.
TITLE optionally specifies the title of the file to be imported."
  (if-let ((id-or-slug (tlon-import-eaf-get-id-or-slug-from-identifier url)))
      (tlon-import-eaf-html id-or-slug title)
    (tlon-import-convert-html-to-markdown url title)))

;; TODO: make it also work with LessWrong
(declare-function tlon-set-file-from-title "tlon")
(defun tlon-import-eaf-html (id-or-slug &optional title)
  "Import the HTML of EAF entity with ID-OR-SLUG to TARGET and convert it to MD.
TITLE optionally specifies the title of the entity to be imported."
  (let* ((response (tlon-import-eaf-request id-or-slug))
	 (object (tlon-import-eaf-get-object id-or-slug))
	 (dir (tlon-repo-lookup :dir :name "uqbar-en"))
	 (subdir (pcase object
		   ('article "articles")
		   ('tag "tags")))
	 (title (or title (pcase object
			    ('article (tlon-import-eaf-get-article-title response))
			    ('tag (tlon-import-eaf-get-tag-title response)))))
	 (target (read-string "Save file in: "
			      (tlon-set-file-from-title title
							      (file-name-concat dir subdir))))
	 (html (pcase object
		 ('article (tlon-import-eaf-get-article-html response))
		 ('tag (tlon-import-eaf-get-tag-html response))))
	 (html-file (tlon-import-save-html-to-file html)))
    (shell-command
     (format tlon-pandoc-convert-from-file html-file target))
    (with-current-buffer (find-file-noselect target)
      (tlon-cleanup-common)
      (tlon-cleanup-eaf)
      (tlon-autofix-all))
    (find-file target)))

(defun tlon-import-save-html-to-file (html)
  "Save the HTML string HTML to a temporary file."
  (let ((filename (make-temp-file "tlon-request-" nil ".html")))
    (with-temp-file filename
      (insert html))
    filename))

(defun tlon-import-convert-html-to-markdown (source &optional title)
  "Convert HTML text in SOURCE to Markdown.
SOURCE can be a URL or a file path. If TITLE is not provided, prompt the user
for one."
  (let* ((target (read-string "Save file in: " (tlon-set-file-from-title title)))
	 (pandoc (if (simple-extras-string-is-url-p source)
		     tlon-pandoc-convert-from-url
		   tlon-pandoc-convert-from-file)))
    (shell-command
     (format pandoc source target))
    (with-current-buffer (find-file-noselect target)
      (tlon-cleanup-common)
      (tlon-autofix-all))
    (find-file target)))

;; TODO: cleanup two functions below
(defun tlon-import-pdf (path &optional title)
  "Import the PDF in PATH to TARGET and convert it to Markdown.
This command requires the user to supply values for the header and footer
elements to be excluded from the conversion, which are different for each PDF.
To determine these values, measure the distance between the top/bottom of the
PDF (which will open in the other window) and note the number of pixels until
the end of the header/footer. (You can measure the number of pixels between two
points by taking a screenshot: note the numbers next to the pointer.) Then enter
these values when prompted.

If TITLE is nil, prompt the user for one."
  (find-file-other-window path)
  (let ((target (read-string "Save file in: " (tlon-set-file-from-title title)))
	(header (read-string "Header: "))
	(footer (read-string "Footer: ")))
    (unless (executable-find "pdftotext")
      (user-error "`pdftotext' not found. Please install it (`brew install poppler') and set `tlon-pdftotext' to its path"))
    (shell-command (format "'%s' -margint %s -marginb %s '%s' '%s'"
			   tlon-pdftotext header footer path target))
    (find-file target)))

(defun tlon-convert-pdf (source destination)
  "Convert PDF in SOURCE to Markdown in DESTINATION."
  (shell-command (format "%s '%s' '%s'"
			 tlon-pdftotext
			 (expand-file-name source)
			 (expand-file-name destination))))

;;;;; EAF API

(defun tlon-import-eaf-article-query (id)
  "Return an EA Forum GraphQL query for post whose ID is ID."
  (concat "{\"query\":\"{\\n  post(\\n    input: {\\n      selector: {\\n        _id: \\\""
	  id
	  "\\\"\\n      }\\n    }\\n  ) {\\n    result {\\n      _id\\n      postedAt\\n      url\\n      canonicalSource\\n      title\\n      contents {\\n        markdown\\n        ckEditorMarkup\\n      }\\n      slug\\n      commentCount\\n      htmlBody\\n      baseScore\\n      voteCount\\n      pageUrl\\n      legacyId\\n      question\\n      tableOfContents\\n      author\\n      user {\\n        username\\n        displayName\\n        slug\\n        bio\\n      }\\n      coauthors {\\n        _id\\n        username\\n        displayName\\n        slug\\n      }\\n    }\\n  }\\n}\\n\"}"))

(defun tlon-import-eaf-tag-query (slug)
  "Return an EA Forum GraphQL query for tag whose slug is SLUG."
  (concat "{\"query\":\"{\\n  tag(input: { selector: { slug: \\\""
	  slug
	  "\\\" } }) {\\n    result {\\n      name\\n      slug\\n      description {\\n        html\\n      }\\n      parentTag {\\n        name\\n      }\\n    }\\n  }\\n}\\n\"}"))

(defun tlon-import-eaf-request (id-or-slug &optional async)
  "Run an EAF request for ID-OR-SLUG.
If ASYNC is t, run the request asynchronously."
  (let* ((object (tlon-import-eaf-get-object id-or-slug))
	 (fun (pcase object
		('article 'tlon-import-eaf-article-query)
		('tag 'tlon-import-eaf-tag-query)
		(_ (error "Invalid object: %S" object))))
	 (query (funcall fun id-or-slug))
	 response)
    (request
      tlon-import-eaf-api-url
      :type "POST"
      :headers '(("Content-Type" . "application/json"))
      :data query
      :parser 'json-read
      :sync (not async)
      :success (cl-function
		(lambda (&key data &allow-other-keys)
		  (setq response (cdr (assoc 'data data)))))
      :error (cl-function
	      (lambda (&rest args &key error-thrown &allow-other-keys)
		(message "Error: %S" error-thrown))))
    response))

(defun tlon-import-eaf-get-article-result (response)
  "Get article details from EA Forum API RESPONSE."
  (let* ((article (cdr (assoc 'post response)))
	 (result (cdr (assoc 'result article))))
    result))

(defun tlon-import-eaf-get-article-html (response)
  "Get article HTML from EA Forum API RESPONSE."
  (let* ((result (tlon-import-eaf-get-article-result response))
	 (html (cdr (assoc 'htmlBody result))))
    html))

(defun tlon-import-eaf-get-article-title (response)
  "Get article title from EA Forum API RESPONSE."
  (let* ((result (tlon-import-eaf-get-article-result response))
	 (title (cdr (assoc 'title result))))
    title))

(defun tlon-import-eaf-get-tag-result (response)
  "Get tag details from EA Forum API RESPONSE."
  (let* ((tag (cdr (assoc 'tag response)))
	 (result (cdr (assoc 'result tag))))
    result))

(defun tlon-import-eaf-get-tag-html (response)
  "Get tag HTML from EA Forum API RESPONSE."
  (let* ((result (tlon-import-eaf-get-tag-result response))
	 (description (cdr (assoc 'description result)))
	 (html (cdr (assoc 'html description))))
    html))

(defun tlon-import-eaf-get-tag-title (response)
  "Get tag title from EA Forum API RESPONSE."
  (let* ((result (tlon-import-eaf-get-tag-result response))
	 (title (cdr (assoc 'name result))))
    (tlon-import-eaf-shorten-title title)))

(defun tlon-import-eaf-shorten-title (title)
  "Return a shortened version of TITLE."
  (string-match "\\([[:alnum:] ,'‘’“”@#$%*\\^`~&\"]*\\)" title)
  (match-string 1 title))

;;;;; EAF validation

(defun tlon-import-eaf-url-regexp (url)
  "Return t if URL is an EAF URL, nil otherwise."
  (not (not (string-match tlon-import-eaf-url-regexp url))))

(defun tlon-import-eaf-article-id-p (identifier)
  "Return t if IDENTIFIER is a post ID, nil otherwise."
  (not (not (string-match (format "^%s$" tlon-import-eaf-article-id-regexp) identifier))))

(defun tlon-import-eaf-tag-slug-p (identifier)
  "Return t if IDENTIFIER is a tag slug, nil otherwise."
  (not (not (string-match (format "^%s$" tlon-import-eaf-tag-slug-regexp) identifier))))

(defun tlon-import-eaf-get-id-or-slug-from-identifier (identifier)
  "Return the EAF post ID or tag slug from IDENTIFIER, if found.
IDENTIFIER can be an URL, a post ID or a tag slug."
  (interactive "sURL: ")
  (if (simple-extras-string-is-url-p identifier)
      (or (tlon-import-eaf-get-id-from-identifier identifier)
	  (tlon-import-eaf-get-slug-from-identifier identifier))
    ;; return id or slug if identifier is an id or slug
    (pcase identifier
      ((pred tlon-import-eaf-article-id-p) identifier)
      ((pred tlon-import-eaf-tag-slug-p) identifier))))

(defun tlon-import-eaf-get-id-from-identifier (identifier)
  "Return the EAF post ID from IDENTIFIER, if found."
  (when-let ((id (or (when (string-match (format "^.+?forum.effectivealtruism.org/posts/%s"
						 tlon-import-eaf-article-id-regexp)
					 identifier)
		       (match-string-no-properties 1 identifier))
		     (when (string-match (format "^.+?forum.effectivealtruism.org/s/%s/p/%s"
						 tlon-import-eaf-article-id-regexp tlon-import-eaf-article-id-regexp)
					 identifier)
		       (match-string-no-properties 2 identifier)))))
    id))

(defun tlon-import-eaf-get-slug-from-identifier (identifier)
  "Return the EAF tag slug from IDENTIFIER, if found."
  (when (string-match (format "^.+?forum.effectivealtruism.org/topics/%s"
			      tlon-import-eaf-tag-slug-regexp)
		      identifier)
    (match-string-no-properties 1 identifier)))

(defun tlon-import-eaf-get-object (id-or-slug)
  "Return the EAF object in ID-OR-SLUG."
  (let ((object (cond ((tlon-import-eaf-article-id-p id-or-slug)
		       'article)
		      ((tlon-import-eaf-tag-slug-p id-or-slug)
		       'tag)
		      (t (user-error "Not an ID or slug: %S" id-or-slug)))))
    object))

(provide 'tlon-import)
;;; tlon-import.el ends here