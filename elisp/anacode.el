;;; anacode.el -- Elisp libraries

;; Author: Ana Code <anacode@sanger.ac.uk>
;; Keywords: perl

(defconst anacode nil
  "The documentation for the anacode libraries.
Features:
  `anacode-perl-syntax' - syntax check your Perl code.
  `anacode-perlcritic'  - run perlcritic on your Perl code.
  `anacode-perldoc'     - run perldoc on your Perl code.
  `anacode-perltidy'    - run perltidy on the region.")

(require 'anacode-perl-syntax)
(require 'anacode-perlcritic)
(require 'anacode-perldoc)
(require 'anacode-perltidy)

(provide 'anacode)

;;; anacode.el ends here
