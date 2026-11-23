-- =====================================================================
-- Site components: turns the data in data/*.yml into HTML.
--   {{< profile-links >}}          social/contact links (data/links.yml)
--   {{< papers section="wp" >}}     papers of one section (data/papers.yml)
--   {{< papers section="wp,wip" >}} several sections together, in file order
--   {{< publications >}}            pre-PhD publications (data/papers.yml)
-- You normally never need to edit this file.
-- =====================================================================

local str = pandoc.utils.stringify

local function is_true(v)
  if v == nil then return false end
  if type(v) == "boolean" then return v end
  local s = str(v):lower()
  return s == "true" or s == "yes"
end

local function nonempty(v)
  return v ~= nil and str(v) ~= ""
end

local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function as_inlines(v)
  if v == nil then return pandoc.Inlines({}) end
  if pandoc.utils.type(v) == "Inlines" then return v end
  if pandoc.utils.type(v) == "Blocks" then return pandoc.utils.blocks_to_inlines(v) end
  return pandoc.Inlines({ pandoc.Str(str(v)) })
end

local function as_blocks(v)
  if v == nil then return pandoc.Blocks({}) end
  local t = pandoc.utils.type(v)
  if t == "Blocks" then return v end
  if t == "Inlines" then return pandoc.Blocks({ pandoc.Para(v) }) end
  return pandoc.Blocks({ pandoc.Para({ pandoc.Str(str(v)) }) })
end

local function raw(html) return pandoc.RawInline("html", html) end
local function rawb(html) return pandoc.RawBlock("html", html) end

-- ------------------------------------------------------------------
-- Profile links
-- ------------------------------------------------------------------
local function profile_links(args, kwargs, meta)
  local links = meta.links
  if links == nil then return pandoc.Null() end
  local out = {}
  for _, l in ipairs(links) do
    if is_true(l.show) and nonempty(l.url) then
      local url = str(l.url)
      local label = str(l.label or "")
      local icon = str(l.icon or "bi bi-link-45deg")
      local ext = url:match("^https?://") and ' target="_blank" rel="noopener"' or ""
      table.insert(out, string.format(
        '<a class="profile-link" href="%s"%s title="%s" aria-label="%s"><i class="%s" aria-hidden="true"></i><span>%s</span></a>',
        esc(url), ext, esc(label), esc(label), esc(icon), esc(label)))
    end
  end
  if #out == 0 then return pandoc.Null() end
  return rawb('<div class="profile-links">' .. table.concat(out, "") .. '</div>')
end

-- ------------------------------------------------------------------
-- Papers
-- ------------------------------------------------------------------
local BUTTONS = {
  { key = "paper",    label = "Paper",    icon = "bi bi-file-earmark-pdf" },
  { key = "appendix", label = "Appendix", icon = "bi bi-journal-text" },
  { key = "slides",   label = "Slides",   icon = "bi bi-easel" },
  { key = "code",     label = "Code",     icon = "bi bi-code-slash" },
  { key = "data",     label = "Data",     icon = "bi bi-database" },
}

local function chip(label, url, icon)
  local ext = ' target="_blank" rel="noopener"'
  return string.format('<a class="paper-chip" href="%s"%s><i class="%s" aria-hidden="true"></i>%s</a>',
    esc(url), ext, esc(icon), esc(label))
end

local function coauthor_inlines(list)
  local names = {}
  for _, c in ipairs(list) do
    local name = as_inlines(c.name)
    if nonempty(c.url) then
      table.insert(names, pandoc.Inlines({ pandoc.Link(name, str(c.url), "", pandoc.Attr("", {}, { { "target", "_blank" }, { "rel", "noopener" } })) }))
    else
      table.insert(names, name)
    end
  end
  if #names == 0 then return nil end
  local res = pandoc.Inlines({ pandoc.Str("with"), pandoc.Space() })
  for i, n in ipairs(names) do
    res:extend(n)
    if #names == 2 and i == 1 then
      res:extend({ pandoc.Space(), pandoc.Str("and"), pandoc.Space() })
    elseif #names > 2 and i < #names - 1 then
      res:extend({ pandoc.Str(","), pandoc.Space() })
    elseif #names > 2 and i == #names - 1 then
      res:extend({ pandoc.Str(","), pandoc.Space(), pandoc.Str("and"), pandoc.Space() })
    end
  end
  return res
end

local function toggle(label, blocks, cls)
  local out = pandoc.Blocks({})
  out:insert(rawb('<details class="paper-toggle ' .. cls .. '"><summary><span class="toggle-icon" aria-hidden="true"></span>' .. label .. '</summary><div class="toggle-body">'))
  out:extend(blocks)
  out:insert(rawb('</div></details>'))
  return out
end

local function render_paper(p)
  local blocks = pandoc.Blocks({})
  blocks:insert(rawb('<article class="paper">'))

  -- badges + title
  local title = pandoc.Inlines({})
  if is_true(p.new) then title:insert(raw('<span class="paper-badge badge-new">New</span> ')) end
  if is_true(p.jmp) then title:insert(raw('<span class="paper-badge badge-jmp">Job Market Paper</span> ')) end
  title:extend(as_inlines(p.title))
  blocks:insert(pandoc.Div(pandoc.Plain(title), pandoc.Attr("", { "paper-title" })))

  -- coauthors
  if p.coauthors and #p.coauthors > 0 then
    local co = coauthor_inlines(p.coauthors)
    if co then blocks:insert(pandoc.Div(pandoc.Plain(co), pandoc.Attr("", { "paper-coauthors" }))) end
  end

  -- status line (e.g. "Draft coming soon", "Submitted", journal name)
  if nonempty(p.status) then
    blocks:insert(pandoc.Div(pandoc.Plain(as_inlines(p.status)), pandoc.Attr("", { "paper-status" })))
  end

  -- buttons: only those with a link filled in
  local chips = {}
  local links = p.links or {}
  for _, b in ipairs(BUTTONS) do
    if nonempty(links[b.key]) then table.insert(chips, chip(b.label, str(links[b.key]), b.icon)) end
  end
  if links.extra then
    for _, e in ipairs(links.extra) do
      if nonempty(e.url) and nonempty(e.label) then
        table.insert(chips, chip(str(e.label), str(e.url), nonempty(e.icon) and str(e.icon) or "bi bi-box-arrow-up-right"))
      end
    end
  end
  if #chips > 0 then
    blocks:insert(rawb('<div class="paper-chips">' .. table.concat(chips, "") .. '</div>'))
  end

  -- expandable abstract / presentations
  if nonempty(p.abstract) then
    blocks:extend(toggle("Abstract", as_blocks(p.abstract), "toggle-abstract"))
  end
  if p.presentations and #p.presentations > 0 then
    local items = {}
    for _, x in ipairs(p.presentations) do table.insert(items, { pandoc.Plain(as_inlines(x)) }) end
    blocks:extend(toggle("Presentations", pandoc.Blocks({ pandoc.BulletList(items) }), "toggle-presentations"))
  end

  blocks:insert(rawb('</article>'))
  return blocks
end

local function papers(args, kwargs, meta)
  -- section can be one value ("wp") or several ("wp,wip"); file order is kept
  local wanted = {}
  for s in str(kwargs["section"] or ""):gmatch("[^,%s]+") do wanted[s] = true end
  local list = meta.papers
  if list == nil then return pandoc.Null() end
  local out = pandoc.Blocks({})
  out:insert(rawb('<div class="paper-list">'))
  local n = 0
  for _, p in ipairs(list) do
    if wanted[str(p.section or "")] and not is_true(p.hide) then
      out:extend(render_paper(p))
      n = n + 1
    end
  end
  out:insert(rawb('</div>'))
  if n == 0 then return pandoc.Null() end
  return out
end

-- ------------------------------------------------------------------
-- Pre-PhD publications
-- ------------------------------------------------------------------
local function publications(args, kwargs, meta)
  local list = meta.publications
  if list == nil then return pandoc.Null() end
  local items = {}
  for _, p in ipairs(list) do
    if not is_true(p.hide) then
      local inl = pandoc.Inlines({})
      inl:extend(as_inlines(p.citation))
      if nonempty(p.url) then
        inl:insert(pandoc.Space())
        inl:insert(raw(chip("Link", str(p.url), "bi bi-box-arrow-up-right")))
      end
      table.insert(items, { pandoc.Plain(inl) })
    end
  end
  if #items == 0 then return pandoc.Null() end
  return pandoc.Div(pandoc.BulletList(items), pandoc.Attr("", { "pub-list" }))
end

return {
  ["profile-links"] = profile_links,
  ["papers"] = papers,
  ["publications"] = publications,
}
