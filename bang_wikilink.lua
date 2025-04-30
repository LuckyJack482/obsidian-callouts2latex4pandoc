-- bang_wikilink.lua
--
-- Thanks ChatGPT

function Para(para)
  local content = para.content
  local result = pandoc.List()
  local i = 1

  while i <= #content do
    local this = content[i]
    local link = content[i + 1]

    if this.t == "Str" and this.text == "!" and link and link.t == "Link" then
      local caption = link.content or {}
      local target = link.target
      print(caption)
      print(target)
      
      -- Create Image
      local img = pandoc.Image(caption, target)

      -- Insert the Image node as a block!
      -- return pandoc.Para(result)
      result:insert(img)
      i = i + 2
    else
      result:insert(this)
      i = i + 1
    end
  end

  return pandoc.Para(result)
end
