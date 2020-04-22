local _, addon = ...
local qlog = addon.qlog

function PMQ_QuestLogFrame_OnLoad(self)
  self:RegisterForDrag("LeftButton")
end

function PMQ_QuestLogFrame_OnDragStart(self)
  self:StartMoving()
end

function PMQ_QuestLogFrame_OnDragStop(self)
  self:StopMovingOrSizing()
end