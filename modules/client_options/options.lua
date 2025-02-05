local defaultOptions = {
    vsync = true,
    showFps = false,
    showPing = false,
    fullscreen = false,
    classicControl = false,
    smartWalk = false,
    preciseControl = false,
    autoChaseOverride = true,
    moveStack = false,
    showStatusMessagesInConsole = true,
    showEventMessagesInConsole = true,
    showInfoMessagesInConsole = true,
    showTimestampsInConsole = true,
    showLevelsInConsole = true,
    showPrivateMessagesInConsole = true,
    showPrivateMessagesOnScreen = true,
    showLeftPanel = false,
    showRightExtraPanel = false,
    openMaximized = false,
    backgroundFrameRate = 201,
    painterEngine = 0,
    enableAudio = true,
    enableMusicSound = true,
    musicSoundVolume = 100,
    enableLights = true,
    drawViewportEdge = false,
    floatingEffect = false,
    ambientLight = 0,
    displayNames = true,
    displayHealth = true,
    displayMana = true,
    displayText = true,
    dontStretchShrink = false,
    turnDelay = 50,
    hotkeyDelay = 70,
    crosshair = 'default',
    enableHighlightMouseTarget = true,
    antiAliasing = true,
    renderScale = 100,
    shadowFloorIntensity = 15
}

local optionsWindow
local optionsButton
local optionsTabBar
local options = {}
local generalPanel
local controlPanel
local consolePanel
local graphicsPanel
local soundPanel
local audioButton

local crosshairCombobox
local renderScaleCombobox

local function setupGraphicsEngines()
    local enginesRadioGroup = UIRadioGroup.create()
    local ogl1 = graphicsPanel:getChildById('opengl1')
    local ogl2 = graphicsPanel:getChildById('opengl2')
    local dx9 = graphicsPanel:getChildById('directx9')
    enginesRadioGroup:addWidget(ogl1)
    enginesRadioGroup:addWidget(ogl2)
    enginesRadioGroup:addWidget(dx9)

    if g_window.getPlatformType() == 'WIN32-EGL' then
        enginesRadioGroup:selectWidget(dx9)
        ogl1:setEnabled(false)
        ogl2:setEnabled(false)
        dx9:setEnabled(true)
    else
        ogl1:setEnabled(g_graphics.isPainterEngineAvailable(1))
        ogl2:setEnabled(g_graphics.isPainterEngineAvailable(2))
        dx9:setEnabled(false)
        if g_graphics.getPainterEngine() == 2 then
            enginesRadioGroup:selectWidget(ogl2)
        else
            enginesRadioGroup:selectWidget(ogl1)
        end

        if g_app.getOs() ~= 'windows' then dx9:hide() end
    end

    enginesRadioGroup.onSelectionChange =
        function(self, selected)
            if selected == ogl1 then
                setOption('painterEngine', 1)
            elseif selected == ogl2 then
                setOption('painterEngine', 2)
            end
        end
end

function init()
    for k, v in pairs(defaultOptions) do
        g_settings.setDefault(k, v)
        options[k] = v
    end

    optionsWindow = g_ui.displayUI('options')
    optionsWindow:hide()

    optionsTabBar = optionsWindow:getChildById('optionsTabBar')
    optionsTabBar:setContentWidget(optionsWindow:getChildById(
                                       'optionsTabContent'))

    g_keyboard.bindKeyDown('Ctrl+Shift+F',
                           function() toggleOption('fullscreen') end)
    g_keyboard.bindKeyDown('Ctrl+N', toggleDisplays)

    generalPanel = g_ui.loadUI('general')
    optionsTabBar:addTab(tr('General'), generalPanel, '/images/optionstab/game')

    controlPanel = g_ui.loadUI('control')
    optionsTabBar:addTab(tr('Control'), controlPanel, '/images/optionstab/controls')

    consolePanel = g_ui.loadUI('console')
    optionsTabBar:addTab(tr('Console'), consolePanel,
                         '/images/optionstab/console')

    graphicsPanel = g_ui.loadUI('graphics')
    optionsTabBar:addTab(tr('Graphics'), graphicsPanel,
                         '/images/optionstab/graphics')

    soundPanel = g_ui.loadUI('audio')
    optionsTabBar:addTab(tr('Audio'), soundPanel, '/images/optionstab/audio')

    optionsButton = modules.client_topmenu.addLeftButton('optionsButton',
                                                         tr('Options'),
                                                         '/images/topbuttons/options',
                                                         toggle)
    audioButton = modules.client_topmenu.addLeftButton('audioButton',
                                                       tr('Audio'),
                                                       '/images/topbuttons/audio',
                                                       function()
        toggleOption('enableAudio')
    end)

    addEvent(function() setup() end)
end

function terminate()
    g_keyboard.unbindKeyDown('Ctrl+Shift+F')
    g_keyboard.unbindKeyDown('Ctrl+N')
    optionsWindow:destroy()
    optionsButton:destroy()
    audioButton:destroy()
end

function setupComboBox()
    crosshairCombobox = generalPanel:recursiveGetChildById('crosshair')

    crosshairCombobox:addOption('Disabled', 'disabled')
    crosshairCombobox:addOption('Default', 'default')
    crosshairCombobox:addOption('Full', 'full')

    crosshairCombobox.onOptionChange = function(comboBox, option)
        setOption('crosshair', comboBox:getCurrentOption().data)
    end

    renderScaleCombobox = graphicsPanel:recursiveGetChildById('renderScale')

    renderScaleCombobox:addOption('50%', 50)
    renderScaleCombobox:addOption('75%', 75)
    renderScaleCombobox:addOption('100%', 100)
    renderScaleCombobox:addOption('150%', 150)
    renderScaleCombobox:addOption('200%', 200)

    renderScaleCombobox.onOptionChange =
        function(comboBox, option)
            setOption('renderScale', comboBox:getCurrentOption().data)
        end
end

function setup()
    setupComboBox()
    setupGraphicsEngines()

    -- load options
    for k, v in pairs(defaultOptions) do
        if type(v) == 'boolean' then
            setOption(k, g_settings.getBoolean(k), true)
        elseif type(v) == 'number' then
            setOption(k, g_settings.getNumber(k), true)
        elseif type(v) == 'string' then
            setOption(k, g_settings.getString(k), true)
        end
    end
end

function toggle()
    if optionsWindow:isVisible() then
        hide()
    else
        show()
    end
end

function show()
    optionsWindow:show()
    optionsWindow:raise()
    optionsWindow:focus()
end

function hide() optionsWindow:hide() end

function toggleDisplays()
    if options['displayNames'] and options['displayHealth'] and
        options['displayMana'] then
        setOption('displayNames', false)
    elseif options['displayHealth'] then
        setOption('displayHealth', false)
        setOption('displayMana', false)
    else
        if not options['displayNames'] and not options['displayHealth'] then
            setOption('displayNames', true)
        else
            setOption('displayHealth', true)
            setOption('displayMana', true)
        end
    end
end

function toggleOption(key) setOption(key, not getOption(key)) end

function setOption(key, value, force)
    if not force and options[key] == value then return end

    local gameMapPanel = modules.game_interface.getMapPanel()

    if key == 'vsync' then
        g_window.setVerticalSync(value)
    elseif key == 'showFps' then
        modules.client_topmenu.setFpsVisible(value)
    elseif key == 'showPing' then
        modules.client_topmenu.setPingVisible(value)
    elseif key == 'fullscreen' then
        g_window.setFullscreen(value)
    elseif key == 'enableAudio' then
        if g_sounds then g_sounds.setAudioEnabled(value) end
        if value then
            audioButton:setIcon('/images/topbuttons/audio')
        else
            audioButton:setIcon('/images/topbuttons/audio_mute')
        end
    elseif key == 'enableMusicSound' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
        end
    elseif key == 'musicSoundVolume' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setGain(value / 100)
        end
        soundPanel:getChildById('musicSoundVolumeLabel'):setText(tr(
                                                                     'Music volume: %d',
                                                                     value))
    elseif key == 'showLeftPanel' then
        modules.game_interface.getLeftPanel():setOn(value)
    elseif key == 'showRightExtraPanel' then
        modules.game_interface.getRightExtraPanel():setOn(value)
    elseif key == 'backgroundFrameRate' then
        local text, v = value, value
        if value <= 0 or value >= 201 then
            text = 'max'
            v = 0
        end
        graphicsPanel:getChildById('backgroundFrameRateLabel'):setText(tr(
                                                                           'Game framerate limit: %s',
                                                                           text))
        g_app.setBackgroundPaneMaxFps(v)
    elseif key == 'enableLights' then
        gameMapPanel:setDrawLights(value and options['ambientLight'] < 100)
        graphicsPanel:getChildById('ambientLight'):setEnabled(value)
        graphicsPanel:getChildById('ambientLightLabel'):setEnabled(value)
    elseif key == 'ambientLight' then
        graphicsPanel:getChildById('ambientLightLabel'):setText(tr(
                                                                    'Ambient light: %s%%',
                                                                    value))
        gameMapPanel:setMinimumAmbientLight(value / 100)
        gameMapPanel:setDrawLights(options['enableLights'])
    elseif key == 'shadowFloorIntensity' then
        graphicsPanel:getChildById('shadowFloorIntensityLevel'):setText(tr(
                                                                            'Shadow floor Intensity: %s%%',
                                                                            value))
        gameMapPanel:setShadowFloorIntensity(1 - (value / 100))
    elseif key == 'drawViewportEdge' then
        gameMapPanel:setDrawViewportEdge(value)
    elseif key == 'floatingEffect' then
        g_map.setFloatingEffect(value)
    elseif key == 'painterEngine' then
        g_graphics.selectPainterEngine(value)
    elseif key == 'displayNames' then
        gameMapPanel:setDrawNames(value)
    elseif key == 'displayHealth' then
        gameMapPanel:setDrawHealthBars(value)
    elseif key == 'displayMana' then
        gameMapPanel:setDrawManaBar(value)
    elseif key == 'displayText' then
        gameMapPanel:setDrawTexts(value)
    elseif key == 'dontStretchShrink' then
        addEvent(function() modules.game_interface.updateStretchShrink() end)
    elseif key == 'preciseControl' then
        g_game.setScheduleLastWalk(not value)
    elseif key == 'turnDelay' then
        controlPanel:getChildById('turnDelayLabel'):setText(tr(
                                                                'Turn delay: %sms',
                                                                value))
    elseif key == 'hotkeyDelay' then
        controlPanel:getChildById('hotkeyDelayLabel'):setText(tr(
                                                                  'Hotkey delay: %sms',
                                                                  value))
    elseif key == 'crosshair' then
        local crossPath = '/images/game/crosshair/'
        local newValue = value
        if newValue == 'disabled' then newValue = nil end
        gameMapPanel:setCrosshairTexture(
            newValue and crossPath .. newValue or nil)
        crosshairCombobox:setCurrentOptionByData(newValue, true)
    elseif key == 'enableHighlightMouseTarget' then
        gameMapPanel:setDrawHighlightTarget(value)
    elseif key == 'floorShadowing' then
        gameMapPanel:setFloorShadowingFlag(value)
        floorShadowingComboBox:setCurrentOptionByData(value, true)
    elseif key == 'antiAliasing' then
        gameMapPanel:setAntiAliasing(value)
    elseif key == 'renderScale' then
        gameMapPanel:setRenderScale(value)
        renderScaleCombobox:setCurrentOptionByData(value, true)
        if not force and value > 100 then
            displayInfoBox(tr('Warning'), tr(
                               'Rendering scale above 100%% will drop performance and visual bugs may occur.'))
        end
    end

    -- change value for keybind updates
    for _, panel in pairs(optionsTabBar:getTabsPanel()) do
        local widget = panel:recursiveGetChildById(key)
        if widget then
            if widget:getStyle().__class == 'UICheckBox' then
                widget:setChecked(value)
            elseif widget:getStyle().__class == 'UIScrollBar' then
                widget:setValue(value)
            end
            break
        end
    end

    g_settings.set(key, value)
    options[key] = value
end

function getOption(key) return options[key] end

function addTab(name, panel, icon) optionsTabBar:addTab(name, panel, icon) end

function removeTab(v)
    if type(v) == "string" then v = optionsTabBar:getTab(v) end

    optionsTabBar:removeTab(v)
end

function addButton(name, func, icon) optionsTabBar:addButton(name, func, icon) end
