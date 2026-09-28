local UpgradeState = class("UpgradeState")

function UpgradeState:ctor()
    self.item = nil                  -- Selected Equipment
    self.supportItem = nil           -- Support Item for increase sucess rate
    self.materials = ArrayList.new() -- Materials for upgrade
end

function UpgradeState:reset()
    self.item = nil
    self.supportItem = nil
    self.materials:clear()
end

return UpgradeState
