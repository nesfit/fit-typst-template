#import "template/fit-thesis.typ": appendix, fit-thesis
#import "common.typ": *

#show: fit-thesis.with(
  type: "habilitation",
  lang: "en",
  title: (
    en: [Opportunities and Threats of Blockchain Technologies],
    cs: [Příležitosti a hrozby blockchainových technologií],
  ),
  // Degrees, if wanted on the title page: before: "…", after: "…".
  author: (name: "Vladimír", surname: "Veselý"),
  // One of "UIFS", "UPSY", "UITS", "UPGM", or (en: [...], cs: [...]).
  department: "UIFS",
  year: 2027,
  abstract: (
    en: [To be written.],
    cs: [Bude doplněno.],
  ),
  keywords: (
    en: [blockchain, forensics, database],
    cs: [blockchain, forenzní analýza, databáze],
  ),
  // declaration: [I declare that …],
  // acknowledgement: [I would like to thank …],
)

// Uncomment for the final version to hide all margin and inline notes.
// #set-margin-note-defaults(hidden: true)

#include "chapters/01-introduction.typ"
#include "chapters/02-abstract.typ"
#include "chapters/03-drafting-the-basic-thesis-structure.typ"
#include "chapters/04-individual-thesis-chapters.typ"
#include "chapters/05-rules-for-bibliographic-citations.typ"
#include "chapters/06-formal-aspect-of-a-thesis.typ"
#include "chapters/07-thesis-submission.typ"
#include "chapters/08-conclusion.typ"

#bibliography(
  ("bib/bibliography.yaml", "bib/zotero.bib", "bib/template.bib"),
  style: "bib/iso-690-2022-numeric-ntk.csl",
)

// Appendices: chapters after this line are "Appendix A", "Appendix B", …
// #show: appendix
// #include "chapters/a1-something.typ"
