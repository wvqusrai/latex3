-- Common settings for LaTeX3 development repo, used by l3build script

checkdeps   = checkdeps   or {maindir .. "/l3backend", maindir .. "/l3kernel"}
typesetdeps = typesetdeps or {maindir .. "/l3backend", maindir .. "/l3kernel"}
unpackdeps  = unpackdeps  or {maindir .. "/l3kernel"}

checkengines    = checkengines
  or {"pdftex", "xetex", "luatex", "ptex", "uptex"}
checksuppfiles  = checksuppfiles  or
  {
    "CaseFolding.txt",
    "fontenc.sty",
    "fontloader-*.lua",
    "ltluatex.lua",
    "lualibs*.lua",
    "luaotfload*.lua",
    "luaotfload-blacklist.cnf",
    "minimal.cls",
    "ot1enc.def",
    "regression-test.cfg",
    "regression-test.tex",
    "SpecialCasing.txt",
    "UnicodeData.txt"
  }
tagfiles = tagfiles or {"*.dtx", "README.md", "CHANGELOG.md"}
unpacksuppfiles = unpacksuppfiles or
  {
    "*.def",
    "*.fd",
    "*.ini",
    "*.ltx",
    "docstrip.tex",
    "fontenc.sty",
    "hyphen.cfg",
    "load-unicode-data.tex",
    "load-unicode-xetex-classes.tex",
    "lualatexquotejobname.lua",
    "luatexconfig.tex",
    "pdftexconfig.tex",
    "texsys.cfg",
    "UnicodeData.txt",
    "UShyphen.tex"
  }

packtdszip  = true

typesetcmds = typesetcmds or "\\AtBeginDocument{\\csname DisableImplementation\\endcsname}"

if checksearch == nil then
  checksearch = false
end
if unpacksearch == nil then
  unpacksearch = false
end

-- Detail how to set the version automatically
function update_tag(file,content,tagname,tagdate)
  local iso = "%d%d%d%d%-%d%d%-%d%d"
  local url = "https://github.com/latex3/latex3/compare/"
  if string.match(content,"%(C%)%s*[%d%-,]+ The LaTeX3 Project") then
    local year = os.date("%Y")
    content = string.gsub(content,
      "%(C%)%s*([%d%-,]+) The LaTeX3 Project",
      "(C) %1," .. year .. " The LaTeX3 Project")
   content = string.gsub(content,year .. "," .. year,year)
   content = string.gsub(content,
     "%-" .. year - 1 .. "," .. year,
     "-" .. year)
   content = string.gsub(content,
     year - 2 .. "," .. year - 1 .. "," .. year,
     year - 2 .. "-" .. year)
  end
  if string.match(file,"%.dtx$") then
    content = string.gsub(content,
      "\n\\ProvidesExpl" .. "(%w+ *{[^}]+} *){" .. iso .. "}",
      "\n\\ProvidesExpl%1{" .. tagname .. "}")
    return string.gsub(content,
      "\n%% \\date{Released " .. iso .. "}\n",
      "\n%% \\date{Released " .. tagname .. "}\n")
  elseif string.match(file, "%.md$") then
    if string.match(file,"CHANGELOG.md") then
      local previous = string.match(content,"compare/(" .. iso .. ")%.%.%.HEAD")
      if tagname == previous then return content end
      content = string.gsub(content,
        "## %[Unreleased%]",
        "## [Unreleased]\n\n## [" .. tagname .."]")
      return string.gsub(content,
        iso .. "%.%.%.HEAD",
        tagname .. "...HEAD\n[" .. tagname .. "]: " .. url .. previous
          .. "..." .. tagname)
    end
    return string.gsub(content,
      "\nRelease " .. iso .. "\n",
      "\nRelease " .. tagname .. "\n")
  end
  return content
end

-- Need to build format files
local function fmt()
  local function mkfmt(engine)
    -- Standard (u)pTeX engines don't have e-TeX
    local cmd = engine
    if string.match(engine,"uptex") then
      cmd = "euptex"
    elseif string.match(engine,"ptex") then
      cmd = "eptex"
    end
    -- Use .ini files if available
    local src = "latex.ltx"
    local ini = string.gsub(engine,"tex","") .. "latex.ini"
    if fileexists(supportdir .. "/" .. ini) then
      src = ini
    end
    local errorlevel = os.execute(
      os_setenv .. " TEXINPUTS=" .. unpackdir .. os_pathsep .. localdir
      .. os_concat .. cmd .. " -etex -ini -output-directory=" .. unpackdir
      .. " " .. src)
    if errorlevel ~= 0 then return errorlevel end
    local fmtname = string.gsub(engine,"tex$","") .. "latex.fmt"
    ren(unpackdir,"latex.fmt",fmtname)
    cp(fmtname,unpackdir,localdir)
    return 0
  end
  local checkengines = options["engine"] or checkengines
  local errorlevel
  for _,engine in pairs(checkengines) do
    errorlevel = mkfmt(engine)
    if errorlevel ~= 0 then return errorlevel end
  end
  return 0
end

function checkinit_hook() return fmt() end
