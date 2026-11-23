# How to edit this website

Day to day, you only edit the files in `data/` and the occasional `.qmd` page.
After any change, run `quarto preview` to see it, then `quarto render`, and push to GitHub.

## Where things live

| I want to change...                          | Edit this file              |
|----------------------------------------------|-----------------------------|
| Papers (titles, abstracts, buttons, status)  | `data/papers.yml`           |
| Pre-PhD publications                         | `data/papers.yml` (bottom)  |
| Email / CV / Scholar / LinkedIn / GitHub      | `data/links.yml`            |
| Home page text (bio, fields, contact)        | `index.qmd`                 |
| Teaching                                     | `teaching.qmd`              |
| CV                                           | replace `files/cv.pdf`, then update the date in `cv.qmd` |
| Menu, footer, site title                     | `_quarto.yml`               |
| Colors                                       | `styles/light.scss`, `styles/dark.scss` |
| Spacing, sizes, layout                       | `styles/custom.css`         |

## Papers: show only what you want

Every paper in `data/papers.yml` has a `links:` block:

    links:
      paper: "files/papers/my-paper.pdf"   # button shown
      appendix: ""                         # empty -> no button
      slides: ""
      code: "https://github.com/einarpaz/my-repo"
      data: ""

- A button appears **only** when its link is filled in.
- `abstract: ""` hides the Abstract toggle.
- `hide: true` removes the whole paper from the site but keeps it in the file.
- `new: true` adds a "New" badge. `jmp: true` adds a "Job Market Paper" badge.
- `presentations:` lists talks behind a "Presentations" toggle.
- Math works anywhere: `$\pi_t$`, `$E_t[w_{t+1}]$`.
- To add a paper, copy an existing block (from `- title:` to the line before the next `- title:`) and edit it.

Put paper PDFs, slides, and appendices in `files/papers/`.
**Important:** the repository is public, so any file you push can be found even if no button links to it. Keep unfinished PDFs in `_private-notes/` until they are ready.

## Links: on/off switches

In `data/links.yml`, set `show: true` or `show: false`. GitHub is currently `false`.

## Adding a page later (e.g. Talks)

1. Create `talks.qmd` with:

        ---
        title: "Talks"
        ---

        ## 2027

        - Conference name, City

2. In `_quarto.yml`, under `navbar: left:`, add:

        - href: talks.qmd
          text: Talks

## Private notes

Use the `_private-notes/` folder. It is never published and never pushed to GitHub.
Avoid `<!-- comments -->` in `.qmd` files: anyone can read them on GitHub and in the page source.

## Before going live

1. Replace the `[Placeholder ...]` text in `index.qmd` and `data/papers.yml` (or set those abstracts to `""`).
2. Run `quarto render`.
3. Follow "Switching from the old site" below.

## Switching from the old site

This folder is a complete replacement for your current site folder. When you are happy with it:

1. In your current folder (`einarpaz.github.io`), delete everything **except the hidden `.git` folder**.
2. Copy everything from this folder into it.
3. In VS Code: `quarto render`, then commit and push.

GitHub Pages keeps publishing from `docs/` on `main`, exactly as now. Your URL does not change.

## Research page layout (now vs. on the market)

**Now:** `research.qmd` shows all current papers under one heading, **Current Research**,
in the order they appear in `data/papers.yml`. Your JMP is first.

**When you go on the market**, replace the "Current Research" part of `research.qmd` with:

    ## Job Market Paper

    {{< papers section="jmp" >}}

    ## Working Papers

    {{< papers section="wp" >}}

    ## Work in Progress

    {{< papers section="wip" >}}

Then in `data/papers.yml`, set the JMP's `section: jmp` (and optionally `jmp: true` for the badge).

**Colors on this page:** blue means clickable (buttons, links, toggles). Gray small caps are
status labels. Nothing else is colored, so attention goes to titles and links.
