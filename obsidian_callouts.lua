--[[
This takes fenced div OR gfm alert syntax and converts it for typst / plain / ODT / DOCX / ICML / HTML
Alert types: note, tip, important, warning, caution
For Typst, install https://typst.app/universe/package/gentle-clues/

> [!tip]
> GFM Alert.
> Some **Tip content**.
> More content: H~2~O.

> [!warning] A Custom title
> GFM Alert with custom title.
>
> My **warning** content.
> Some *more* content.

:::note
Fenced Div. 

Some note content. 
More *content*.
:::

::: {.important title="Custom Title"}
Some content.
:::

Version:   0.11
Copyright: (c) 2024 Ian Max Andolina License=MIT, see LICENSE for details
]]

stringify = pandoc.utils.stringify
pdType = pandoc.utils.type

local alerts = pandoc.List({'note', 'abstract', 'info', 'todo', 'tip', 'success', 'question', 'warning', 'failure', 'danger', 'bug', 'example', 'quote'})
-- local preIcon = pandoc.List({"L","T","M","S","B"})
-- local gentleClues = pandoc.List{'abstract', 'info', 'question', 'memo', 'task', 
-- 'tip', 'success', 'warning', 'error', 'example'}

-- Convert the given string to title case using gsub
--
-- @param input string
-- @return string
local function titleCase(input)
	return input:gsub("(%w)(%w*)",function(firstChar, rest) return pandoc.text.upper(firstChar) .. rest end)
end

-- Check if the given value is a pandoc.List or pandoc.Inlines.
--
-- @param input item
-- @return true / false
local function isPandocList(input)
	return pdType(input) == 'List' or pdType(input) == 'Inlines'
end

-- Inject alert Title text into the content
--
-- @param content the content of the alert
-- @param alert the alert name
-- @param customTitle the [optional] custom title
-- @return modified content
local function injectTitle(content, alert, customTitle)
	local _,alertidx = alerts:find(alert)
	if not alerts:includes(alert) then alert,alertidx = alerts[1],1 end
	if isPandocList(customTitle) then customTitle = stringify(customTitle) end
	
	local thisTitle = (customTitle or titleCase(alert))
	
	if isPandocList(content) then
		content:insert(1, pandoc.Str(thisTitle))
		content:insert(2, pandoc.LineBreak())
	end
	return content
end

-- Converts the alert to a set of default obsidian callouts
--
-- @param alert the alert name
-- @param customTitle the [optional] custom title
-- @return the callout name
local function createLatexCallout(alert, customTitle)
	local adjustedAlert = alert
	local adjustedTitle = titleCase(alert)
	if alert == 'summary' or alert == 'tldr' then
		adjustedAlert = 'abstract'
	elseif alert == 'hint' or alert == 'important' then
		adjustedAlert = 'tip'
	elseif alert == 'check' or alert == 'done' then
		adjustedAlert = 'success'
	elseif alert == 'help' or alert == 'faq' then
		adjustedAlert = 'question'
	elseif alert == 'caution' or alert == 'attention' then
		adjustedAlert = 'warning'
	elseif alert == 'fail' or alert == 'missing' then
		adjustedAlert = 'failure'
	elseif alert == 'error' then
		adjustedAlert = 'danger'
	elseif alert == 'cite' then
		adjustedAlert = 'quote'
  -- custom callouts
  elseif alert == 'image' then
		adjustedAlert = 'image'
  elseif alert == 'schematic' then
		adjustedAlert = 'schematic'
  elseif alert == 'graph' then
		adjustedAlert = 'graph'
	elseif not alerts:includes(alert) then
		adjustedAlert = 'note'
	end
  return adjustedAlert
end

-- Create the gentle clues prefix from the alert name and optional custom title
--
-- @param alert the alert name
-- @param customTitle the [optional] custom title
-- @return the prefix string
local function createTypstPrefix(alert, customTitle)
	local adjustedAlert = alert
	local adjustedTitle = titleCase(alert)
	if alert == 'note' then
		adjustedAlert = 'info'
	elseif alert == 'important' then
		adjustedAlert = 'memo'
	elseif alert == 'caution' then
		adjustedAlert = 'warning'
	elseif not gentleClues:includes(alert) then
		adjustedAlert = 'example'
	end
	if customTitle then
		return "\n\n#" .. adjustedAlert .. '(title: "' .. stringify(customTitle) .. '")['
	elseif alert ~= adjustedAlert then
		return "\n\n#" .. adjustedAlert .. '(title: "' .. adjustedTitle .. '")['
	else
		return "\n\n#" .. adjustedAlert .. '['
	end
end

-- Creates an attribute with a class and a custom style
--
-- @param alert the alert name
-- @return the attributes table
local function addClassAndStyle(alert)
	return pandoc.Attr({class = alert,['custom-style'] = titleCase(alert)})
end

-- Converts alert to a Typst Raw block
--
-- @param content the content of the alert
-- @param alert the alert name
-- @param customTitle the [optional] custom title
-- @return the wrapped content
local function wrapTypst(content, alert, customTitle)
	local prefix = createTypstPrefix(alert, customTitle)
	local rawcontent = pandoc.write(pandoc.Pandoc(content),'typst'):gsub("\n$","")
	return pandoc.RawBlock('typst', prefix .. rawcontent .. "]\n\n")
end

-- Wraps the content of a Plain alert in a Div with line breaks and custom style
--
-- @param content the content of the alert
-- @param alert the alert name
-- @return the wrapped content
local function wrapPlain(content, alert)
	content[1].content:insert(1, pandoc.LineBreak()) -- Insert line break at the start
	content[1].content:insert(1, pandoc.Str('----------------------------------')) -- Insert separator line
	content[#content].content:insert(pandoc.LineBreak()) -- Insert line break at the end
	content[#content].content:insert(pandoc.Str('----------------------------------')) -- Insert separator line
	return pandoc.Div(content, addClassAndStyle(alert)) -- Add class and style to the Div
end

-- Wraps the content of an alert into a LaTeX tcolorbox environment
--
-- @param content the content of the alert
-- @param alert the alert name
-- @param customTitle the [optional] custom title
-- @return the wrapped content
local function wrapLatex(content, alert, customTitle)
    local customAlert = createLatexCallout(alert, customTitle)
    local envName = titleCase(customAlert) .. "Box"
    local titlePart = ""
    if customTitle then
        titlePart = "[" .. stringify(customTitle) .. "]"
    end

    local beginEnv = pandoc.RawBlock('latex', "\\begin{" .. envName .. "}" .. titlePart)
    local endEnv = pandoc.RawBlock('latex', "\\end{" .. envName .. "}")
    
    local blocks = pandoc.List()
    blocks:insert(beginEnv)
    for _, block in ipairs(content) do
        blocks:insert(block)
    end
    blocks:insert(endEnv)
    
    return blocks
end

-- Wraps the content of an alert in a Div with custom style
--
-- @param content the content of the alert
-- @param alert the alert name
-- @return the wrapped content
local function wrapOther(content, alert)
	return pandoc.Div(content, addClassAndStyle(alert))
end

--=======================================================================
--=======================================================================Filter functions
--=======================================================================

-- Pandoc converts GFM alerts to classed Divs, and fenced divs with the same class also get processed here
function Div(d)
	local alert = d.classes[1]
	local customTitle = d.attributes['title']
	if not alerts:includes(alert) then return end
	
	if d.content[1].classes and d.content[1].classes:includes('title') then
		d.content:remove(1) -- remove title paragraph to give us more flexibility
	end
	
  if not (FORMAT:match 'typst'  or FORMAT:match 'latex' ) then
		d.content[1].content = injectTitle(d.content[1].content, alert, customTitle) -- add our alert title inline to the content
	end
	
	if FORMAT:match('typst') then
		return wrapTypst(d.content, alert, customTitle)
  elseif FORMAT:match('latex') then
      return wrapLatex(d.content, alert, customTitle)
	elseif FORMAT:match('plain') then
		return wrapPlain(d.content, alert)
	else
		return wrapOther(d.content, alert)
	end
end

-- GFM alerts with a custom title are emitted as blockquotes so they must be caught here
function BlockQuote(bq)
	local firstBlock = bq.content[1].content
  -- print(firstBlock)
  local matching = string.match(stringify(firstBlock[1]),"^%[%!(%a+)%]%s?")
  if matching == nil then return end
	local alert = pandoc.text.lower(matching)
  -- print("----------------------------\n\n\n\n\n\n\n\n")
	if alert == nil then return end
	local customTitle = pandoc.List()
	local newContent = pandoc.List()
	
	for j = 2, #firstBlock do
		if firstBlock[j].tag == "SoftBreak" then break end
		customTitle:insert(firstBlock[j])
	end
	for j = #customTitle+2, #firstBlock do
		newContent:insert(firstBlock[j])
	end
	if #customTitle > 0 and customTitle[1].tag == "Space" then customTitle:remove(1) end
	if #newContent > 0 and newContent[1].tag == "SoftBreak" then newContent:remove(1) end

	if not (FORMAT:match 'typst' or FORMAT:match 'latex') then
		newContent = injectTitle(newContent, alert, stringify(customTitle)) -- add our alert title inline to the content
	end
	
	local content = bq.content:clone()
	content[1] = pandoc.Para(newContent)
	
	if FORMAT:match('typst') then
		return wrapTypst(content, alert, customTitle)
  elseif FORMAT:match('latex') then
      return wrapLatex(content, alert, customTitle)
	elseif FORMAT:match('plain') then
		return wrapPlain(content, alert)
	else
		return wrapOther(content, alert)
	end
end

function Meta(meta)
    if FORMAT:match('latex') then
        local header_injection = [[
\usepackage[most]{tcolorbox}
\usepackage{shellesc}
\usepackage{svg}
% TO FIX
\svgpath{{icons/}{lucide_personal}}

% 
\definecolor{callout-color}{HTML}{909090}
\definecolor{callout-red-color}{RGB}{251, 70, 76}
\definecolor{callout-blue-color}{RGB}{2, 122, 255}
\definecolor{callout-cyan-color}{RGB}{83, 223, 221}
\definecolor{callout-orange-color}{RGB}{233, 151, 63}
\definecolor{callout-green-color}{RGB}{68, 207, 110}
\definecolor{callout-purple-color}{RGB}{168, 130, 255}
\definecolor{callout-gray-color}{RGB}{158, 158, 158}
\definecolor{callout-yellow-color}{RGB}{176, 187, 0}
\definecolor{callout-color-frame}{HTML}{acacac}
\definecolor{callout-note-color-frame}{HTML}{4582ec}
\definecolor{callout-important-color-frame}{HTML}{d9534f}
\definecolor{callout-warning-color-frame}{HTML}{f0ad4e}
\definecolor{callout-tip-color-frame}{HTML}{02b875}
\definecolor{callout-caution-color-frame}{HTML}{fd7e14}

% Default Obsidian callouts
\newtcolorbox{NoteBox}[1][]{colback=callout-blue-color!5!white,colframe=callout-blue-color!85!black,title={\includesvg[height=0.6\baselineskip]{pencil_white} \; #1}}
\newtcolorbox{AbstractBox}[1][]{colback=callout-cyan-color!5!white,colframe=callout-cyan-color!85!black,title={\includesvg[height=0.6\baselineskip]{clipboard-list_white} \; #1}}
\newtcolorbox{InfoBox}[1][]{colback=callout-blue-color!5!white,colframe=callout-blue-color!85!black,title={\includesvg[height=0.6\baselineskip]{info_white} \; #1}}
\newtcolorbox{TodoBox}[1][]{colback=callout-blue-color!5!white,colframe=callout-blue-color!85!black,title={\includesvg[height=0.6\baselineskip]{circle-check_white} \; #1}}
\newtcolorbox{TipBox}[1][]{colback=callout-cyan-color!5!white,colframe=callout-cyan-color!85!black,title={\includesvg[height=0.6\baselineskip]{flame_white} \; #1}}
\newtcolorbox{SuccessBox}[1][]{colback=callout-green-color!5!white,colframe=callout-green-color!85!black,title={\includesvg[height=0.6\baselineskip]{check_white} \; #1}}
\newtcolorbox{QuestionBox}[1][]{colback=callout-orange-color!5!white,colframe=callout-orange-color!85!black,title={\includesvg[height=0.6\baselineskip]{circle-help_white} \; #1}}
\newtcolorbox{WarningBox}[1][]{colback=callout-orange-color!5!white,colframe=callout-orange-color!85!black,title={\includesvg[height=0.6\baselineskip]{triangle-alert_white} \; #1}}
\newtcolorbox{FailureBox}[1][]{colback=callout-red-color!5!white,colframe=callout-red-color!85!black,title={\includesvg[height=0.6\baselineskip]{x_white} \; #1}}
\newtcolorbox{DangerBox}[1][]{colback=callout-red-color!5!white,colframe=callout-red-color!85!black,title={\includesvg[height=0.6\baselineskip]{zap_white} \; #1}}
\newtcolorbox{BugBox}[1][]{colback=callout-red-color!5!white,colframe=callout-red-color!85!black,title={\includesvg[height=0.6\baselineskip]{bug_white} \; #1}}
\newtcolorbox{ExampleBox}[1][]{colback=callout-purple-color!5!white,colframe=callout-purple-color!85!black,title={\includesvg[height=0.6\baselineskip]{list_white} \; #1}}
\newtcolorbox{QuoteBox}[1][]{colback=callout-gray-color!5!white,colframe=callout-gray-color!85!black,title={\includesvg[height=0.6\baselineskip]{quote_white} \; #1}}

% My custom callouts
\newtcolorbox{ImageBox}[1][]{colback=callout-blue-color!5!white,colframe=callout-blue-color!85!black,title={\includesvg[height=0.6\baselineskip]{image_white} \; #1}}
\newtcolorbox{GraphBox}[1][]{colback=callout-cyan-color!5!white,colframe=callout-cyan-color!85!black,title={\includesvg[height=0.6\baselineskip]{chart-line_white} \; #1}}
\newtcolorbox{CircuitBox}[1][]{colback=callout-yellow-color!5!white,colframe=callout-yellow-color!85!black,title={\includesvg[height=0.6\baselineskip]{circuit-board_white} \; #1}}

]]
        local raw_header = pandoc.RawBlock('latex', header_injection)
        
        -- If 'header-includes' already exists, append to it
        if meta['header-includes'] then
            table.insert(meta['header-includes'], raw_header)
        else
            meta['header-includes'] = {raw_header}
        end
        return meta
    end
end
