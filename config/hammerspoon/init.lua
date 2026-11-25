local function pressDown()
    hs.eventtap.keyStroke({}, "down", 0)
end

local function pressUp()
    hs.eventtap.keyStroke({}, "up", 0)
end

-- Mapeia Control + J para Seta para Baixo (suporta pressionar e segurar para repetir)
hs.hotkey.bind({"ctrl"}, "j", pressDown, nil, pressDown)

-- Mapeia Control + K para Seta para Cima (suporta pressionar e segurar para repetir)
hs.hotkey.bind({"ctrl"}, "k", pressUp, nil, pressUp)
