local events = {}

local methods = {
  ["AssertPublished"] = function(self, event, times)
    local tracker = self.publish[event]
    assert(tracker, event.." was not published")
    if times then
      assert(tracker.count == times,
        string.format("Expected %s to be published %i time(s), but was published %i time(s).",
        event, times, tracker.count))
    end
  end,
  ["AssertNotPublished"] = function(self, event)
    local tracker = self.publish[event]
    if tracker then
      error(string.format("%s was not expected to be published, but it was published %i time(s).",
        event, tracker.count))
    end
  end,
  ["AssertHasSubscriptions"] = function(self, event, count)
    local tracker = self.subscriptions[event]
    assert(tracker, event.." has no active subscriptions")
    if count then
      local totalSubs = 0
      for _, _ in pairs(tracker) do
        totalSubs = totalSubs + 1
      end
      assert(totalSubs == count,
        string.format("Expected %s to have %i subscriptions, but has %i subscriptions.",
        event, count, totalSubs))
    end
  end,
  ["AssertHasNoSubscriptions"] = function(self, event)
    local tracker = self.subscriptions[event]
    assert(not tracker,
      string.format("Expected %s to have no active subscriptions", event))
  end,
  ["GetPublishPayload"] = function(self, event, times)
    -- Unless otherwise, assume the event should have been Published exactly once
    times = times or 1
    self:AssertPublished(event, times)
    return table.unpack(self.publish[event].payloads[times])
  end,
  ["Reset"] = function(self)
    self.publish = {}
    self.subscriptions = {}
  end
}

function events:SpyOnEvents(broker)
  local spy = {
    publish = {},
    subscriptions = {}
  }

  local publish = broker.Publish
  broker.Publish = function(self, event, ...)
    local tracker = spy.publish[event]
    if not tracker then
      tracker = {
        count = 0,
        payloads = {}
      }
      spy.publish[event] = tracker
    end
    tracker.count = tracker.count + 1
    table.insert(tracker.payloads, { ... })
    publish(self, event, ...)
  end

  local subscribe = broker.Subscribe
  broker.Subscribe = function(self, event, handlerFunc, options)
    local key = subscribe(self, event, handlerFunc, options)
    local tracker = spy.subscriptions[event]
    if not tracker then
      tracker = {}
      spy.subscriptions[event] = tracker
    end
    tracker[key] = true
    return key
  end

  local unsubscribe = broker.Unsubscribe
  broker.Unsubscribe = function(self, event, key)
    local result = unsubscribe(self, event, key)
    local tracker = spy.subscriptions[event]
    if tracker then
      tracker[key] = nil

      local isLast = true
      for _, _ in pairs(tracker) do
        isLast = false
        break
      end
      if isLast then
        spy.subscriptions[event] = nil
      end
    end
    return result
  end

  for name, method in pairs(methods) do
    spy[name] = method
  end

  return spy
end

return events