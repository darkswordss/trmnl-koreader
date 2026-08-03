--[[--
Runs inside KOReader's busted suite. From a KOReader checkout with this plugin
and this spec symlinked in (plugins/trmnl.koplugin, spec/unit/trmnl_spec.lua):

    ./kodev test front trmnl_spec.lua

Covers the /api/display outcomes that matter: the API reports device and token
problems as HTTP 200 with an error body, so "no image_url" is the only signal
the plugin gets, and it has to say something useful about it.
]]

describe("TRMNL display plugin", function()
    local TrmnlDisplay

    setup(function()
        require("commonrequire")
        require("ui/network/manager").afterWifiAction = function() end
        TrmnlDisplay = dofile("plugins/trmnl.koplugin/main.lua")
    end)

    -- Drives the real _performFetch with a canned API response and returns the
    -- message the user would have been shown.
    local function message_for(response, image_path)
        local seen
        local instance = setmetatable({
            fetchScreenMetadata   = function() return response end,
            handleFetchError      = function(_, msg) seen = msg end,
            updateRefreshInterval = function() end,
            downloadImageIfNeeded = function() return image_path end,
            finalizeFetchSuccess  = function() end,
        }, { __index = TrmnlDisplay })

        instance:_performFetch()
        return seen
    end

    it("surfaces the server's error text", function()
        assert.is_equal("Device not found",
            message_for({ status = 500, error = "Device not found" }))
    end)

    it("falls back to the status when the body carries no error text", function()
        assert.is_equal("status 500", message_for({ status = 500 }))
    end)

    it("stays generic when the request itself failed", function()
        assert.is_equal("Failed to fetch screen metadata", message_for(nil))
    end)

    it("stays generic for an empty body", function()
        assert.is_equal("Failed to fetch screen metadata", message_for({}))
    end)

    it("leaves download failures to the download path", function()
        assert.is_equal("Failed to download image",
            message_for({ image_url = "https://example.invalid/a.png" }, nil))
    end)
end)
