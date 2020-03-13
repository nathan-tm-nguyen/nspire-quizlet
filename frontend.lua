platform.apilevel = "2.5"
    local auto = true
    local searchBoth = false
    local viewingDefinition = false
    local searchBar = D2Editor.newRichText()
    local results = D2Editor.newRichText()
    local entries = {
    }
    local matches = {}
    local tracker = {}
    local payload = ""
    local cursor = 0
    local width = 0
    local height = 0
    
    menu = {
        {"Search Options:",
            {"Auto Search", function() auto = true end},
            {"Manual Search", function() auto = false end},
            {"Term Search", function() termsOnly = true end},
            {"Term and Def Search", function() searchBoth = true end},
        },
        {"Font Sizes:",
                {"Size 9", function() results:setFontSize(9) end},
                {"Size 12", function() results:setFontSize(12) end},
                {"Size 16", function() results:setFontSize(16) end},
        }
    }
    toolpalette.register(menu)
    function trim(s)
       return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
    function pairsByKeys (t, f)
        local a = {}
        for n in pairs(t) do table.insert(a, n) end
        table.sort(a, f)
        local i = 0      
        local iter = function ()  
            i = i + 1
            if a[i] == nil then return nil
                else return a[i], t[a[i]]
            end
        end
        return iter
    end
    function on.resize()
        width = platform.window:width()
        height = platform.window:height()
        searchBar:move(width - width * 0.985, height - height * 0.97):
        resize(width * 0.975, height * 0.11):
        setFocus():setExpression("", 0, 0):
        setMainFont("sansserif","r"):
        setFontSize(9):
        setTextChangeListener(function() if auto then main() end end):
        setFocus():
        registerFilter { 
            enterKey = function()
                if not auto then
                    main()
                end
                results:setFocus()
                return true
            end,
            arrowDown = function()
                if not auto then
                    main()
                end
                results:setFocus()
                return true
            end
        }
        results:move(width - width * 0.985, height - height * 0.83):
        resize(width * 0.975, height * 0.81):setText(""):
        setMainFont("sansserif","r"):
        setFontSize(7):
        setReadOnly():
        registerFilter { 
            enterKey = function()
                if not viewingDefinition and results:getText() ~= nil and matches ~= nil then
                    _, cursor, _ = results:getExpressionSelection()
                    local lower = 0
                    for i = 1, #tracker do
                        if cursor >= lower and cursor <= tracker[i] then
                            if (entries[matches[i]] ~= nil) then
                                results:setExpression(entries[matches[i]], 0, 0)              
                            else
                                 results:setText("No definition available!")
                            end
                            viewingDefinition = true
                        end
                        lower = tracker[i] + 1
                    end
                end
                return true
            end,
            escapeKey = function()
                if viewingDefinition then
                    results:setExpression(payload, cursor, cursor)
                    viewingDefinition = false
                else
                    searchBar:setFocus()
                end
                return true
            end
        }
    end
    function on.paint(gc)
        gc:drawRect(width - width * 0.99, height - height * 0.98, width * 0.98, height * 0.12)
        gc:drawRect(width - width * 0.99, height - height * 0.835, width * 0.98, height * 0.82)
    end
    function getQuery()
        local text = searchBar:getText()
        if text ~= nil then
            text = trim(text)
            if text ~= "" and not text:find('%', 1, true) then
                return text
            else
                return nil
            end
        else
            return nil
        end
    end
    function search(query)
        matches = {}
        local k = 1
        for term, def in pairsByKeys(entries) do
            if searchBoth then
                if query == "." or term:lower():find(query:lower()) or def:lower():find(query:lower()) then    
                    matches[k] = term
                    k = k + 1
                end
            elseif query == "." or term:lower():find(query:lower()) then    
                matches[k] = term
                k = k + 1
            end
        end
    end
    function populateResults(matches)
        if #matches == 0 then
           results:setText("")
           return
        end
        payload = ""
        for i = 1, #matches do
            payload = payload..matches[i].."\n"
            tracker[i] = payload:len() - 1
        end
        payload = trim(payload)
        results:setExpression(payload, tracker[1], tracker[1])
    end
    function main()
        print(searchBoth)
        local query = getQuery()
        if query ~= nil then
            search(query)
            populateResults(matches)
        else 
            results:setText("")
        end
    end