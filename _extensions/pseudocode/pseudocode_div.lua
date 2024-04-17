-- quarto.log.output("====== Log output ======")

-- function pprint(v)
--   print("-----------------------------")
--   print(v)
--   print(type(v))
--   print("-----------------------------")
-- end

function to_string(el)
  return pandoc.utils.stringify(el)
end

-- https://stackoverflow.com/questions/656199/search-for-an-item-in-a-lua-list
function Set(list)
  local set = {}
  for _, l in ipairs(list) do
    set[l] = true
  end
  return set
end

function stringify_el_pseudocode_plain(el)
  -- 3 examples of input:
  --   Strong [ Str "Comment" ]
  --   Space
  --   Str "Sample"
  if el.t == "Str" then
    return el.text
  elseif el == pandoc.Space {} then
    return " "
  elseif el.t == "Link" then
    return link_to_Call(el)
  elseif el.t == "Math" then
    if el.mathtype == "InlineMath" then
      -- el.text = string.gsub(el.text, "\\", "\\\\")
      return "$" .. el.text .. "$"
    elseif el.mathtype == "DisplayMath" then
      -- el.text = string.gsub(el.text, "\\", "\\\\")
      quarto.log.output("html does not support DisplayMath format.")
      return "$$" .. el.text .. "$$"
    end
  elseif el.t == "Code" then
    return "`" .. el.text .. "`"
  elseif el.t == "Emph" then
    return "\\textit{" .. el.content[1].text .. "}"
    -- return "*" .. el.content[1].text .. "*"
  elseif el.t == "Strong" then
    -- return "**" .. el.content[1].text .. "**"
    return "\\textbf{" .. el.content[1].text .. "}"
    -- return pandoc.Strong(el.content[1].text)
  elseif el.t == "Quoted" then
    if el.quotetype == "DoubleQuote" then
      return '"' .. pandoc.utils.stringify(pandoc.Span(el.content)) .. '"'
      -- pprint(el.content[1].text)
      -- return '\\"' .. el.content[1].text .. '\\"'
    elseif el.quotetype == "SingleQuote" then
      return "'" .. pandoc.utils.stringify(pandoc.Span(el.content)) .. "'"
    end
  elseif el.t == "SoftBreak" then
    return "\\n"
  else
    return pandoc.utils.stringify(el)
    -- print(el)
  end
end

function stringify_el_pseudocode_para(el)
  -- 3 examples of input:
  --   Strong [ Str "Comment" ]
  --   Space
  --   Str "Sample"
  if el.t == "Str" then
    return el.text
  elseif el == pandoc.Space {} then
    return " "
  elseif el.t == "Math" then
    if el.mathtype == "InlineMath" then
      -- el.text = string.gsub(el.text, "\\", "\\\\")
      return "$" .. el.text .. "$"
    elseif el.mathtype == "DisplayMath" then
      -- el.text = string.gsub(el.text, "\\", "\\\\")
      quarto.log.output("html does not support DisplayMath format.")
      return "$$" .. el.text .. "$$"
    end
  elseif el.t == "Code" then
    return "`" .. el.text .. "`"
  elseif el.t == "Emph" then
    return "*" .. el.content[1].text .. "*"
  elseif el.t == "Strong" then
    return "**" .. el.content[1].text .. "**"
  elseif el.t == "Quoted" then
    if el.quotetype == "DoubleQuote" then
      return '\"' .. pandoc.utils.stringify(pandoc.Span(el.content)) .. '\"'
      -- pprint(el.content[1].text)
      -- return '\\"' .. el.content[1].text .. '\\"'
    elseif el.quotetype == "SingleQuote" then
      return "'" .. pandoc.utils.stringify(pandoc.Span(el.content)) .. "'"
    end
  elseif el.t == "SoftBreak" then
    return "\n"
  else
    return pandoc.utils.stringify(el)
    -- print(el)
  end
end

function stringify_tale(table)
  -- input: *.content
  local text = ""
  for index, value in ipairs(table) do
    text = text .. stringify_el_pseudocode_plain(value)
  end
  return text
end

function link_to_Call(v)
  if v.t == "Link" and v.target == "Call" then
    assert(#v.content == 2)
    local v2 = v.content[2]
    assert(v2.mathtype == "InlineMath")
    if string.sub(v2.text,1, 1) == "(" and string.sub(v2.text,-1,-1) == ")" then
      -- print(string.sub(v2.text,2, -2))
      v2 = "$".. string.sub(v2.text,2, -2) .. "$"
    end
    -- print(stringify_el(v2))
      -- print(v3)
    -- print("\\call{" .. to_string(v.content[1]) .. "}" .. stringify_el(v2))
    return "\\Call{" .. to_string(v.content[1]) .. "}{" .. stringify_el_pseudocode_plain(v2) .. "}"
  end
end

function Div(div)
  if div.classes[1] == "test" then
    pandoc.walk_block(div, {
      Plain = function(plain)
        for i, v in ipairs(plain.content) do
          link_to_Call(v)
        end
      end
    })
  end
  if div.classes[1] == "pseudocode" then
    local Begin = ""
    local End = "\n\\end{algorithmic}\n\\end{algorithm}"
    -- print("====== Div pseudocode output ======")
    pandoc.walk_block(div, {
      Para = function(para)
        local text = ""
        for i, el in ipairs(para.content) do
          text = text .. stringify_el_pseudocode_para(el)
        end
        -- pprint(text)
        Begin = Begin .. text
      end,
      Header = function(h)
        -- print("Header",stringify_tale(h.content))
        Begin = Begin ..
        '\n\\begin{algorithm}\n' .. '\\caption{' .. stringify_tale(h.content) .. '}\n\\begin{algorithmic}\n'
      end
      ,
      Plain = function(plain)
        -- pandoc.walk_block(plain, {
        --   RawInline = function(raw)
        --     return pandoc.SoftBreak()
        --   end
        -- })
        Begin = Begin .. plain_to_pseudocode(plain)
        -- print(Begin)
      end,
    })
    -- print(Begin)
    all = Begin .. End
    return pandoc.CodeBlock(all, { "", { "pseudocode" }, {} })
  end
end

function plain_to_pseudocode(plain)
  -- input:
  --     Plain
  --       [ Strong [ Str "Comment" ]
  --       , Space
  --       , Str "Sample"
  --       , Space
  --       , Str "random"
  --       , Space
  --       , Str "step"
  --       ]

  -- Repeat <-> Util
  -- 依序分類下面
  --  <補上判斷 Procedure and Function
  --  要不要 State
  --  要不要 End
  --  要不要 bracket {}

  -- \\If{blabla bla}
  local need_brackets = Set { "If", "ElsIf", "Comment", "Until", "While", "For", "ForAll" }
  -- local need_brackets = Set { "If" }

  -- \\Ensure blabla bla
  local no_need_brackets = Set { "Require", "Ensure", "Else", "Repeat", "Return", "EndIf", "EndFor", "EndProcedure", "EndFunction", "Print", "Break", "Continue", "EndWhile" }

  -- local no_need_State = Set { "Require", "Ensure", "If", "ElsIf", "While", "For", "Until", "" }
  local Procedure_and_Function = Set {"Function", "Procedure"}
  -- local need_End = Set { "If", "Procedure", "Function", "While", "For", }

  local Begin = ""
  local End = ""

  -- 先添加第一項
  local test = plain.content[1]
  -- 判斷是不是 Procedure and Function
  if test.t == "Strong" and Procedure_and_Function[to_string(test)] then
    Begin = Begin .. '\\' .. to_string(test) .. '{' .. to_string(plain.content[3]) .. '}{'
    End = '}' .. End 
    for i, v in ipairs(plain.content) do
      if i > 3 then 
        -- 去除括號
        if string.sub(to_string(v),1,1) == "(" and string.sub(to_string(v),-1,-1) == ")" then
          v = string.sub(to_string(v),2,-2)
          v = pandoc.Math('InlineMath',v)
        end
        Begin = Begin .. stringify_el_pseudocode_plain(v)
      end
    end
    -- pprint(Begin .. End)
    return Begin .. End
  -- 判斷要不要 \State
  elseif test.t == "Strong" and (need_brackets[to_string(test)] or no_need_brackets[to_string(test)]) then
    -- 這裡是不加 \State
    -- **If** => \If
    Begin = Begin .. "\\" .. to_string(test)

    -- 接著添加第二項以後
    -- 判斷要不要 bracket {}
    -- **If** => \If{}
    if need_brackets[to_string(test)] then
      Begin = Begin .. '{'
      End = '}' .. End 
    end

    -- 添加後面東西
    for i, v in ipairs(plain.content) do
      if i > 1 then
        -- **Require** some preconditions 會有多一個空格
        Begin = Begin .. stringify_el_pseudocode_plain(v)
      end
    end

  -- 這裏是有 \State 的
  ---- 放 \State 的不會有 bracket
  else
    Begin = Begin .. "\\State "
    for i, v in ipairs(plain.content) do
      Begin = Begin .. stringify_el_pseudocode_plain(v)
    end
  end

  return Begin .. End
end
