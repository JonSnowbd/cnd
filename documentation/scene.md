## What?

The scene is the backbone of your conductor games! It houses many layers, of each many entities.
A scene should be extended, and then use the `:new` constructor from Classic to
populate it with entities.

## Layers

You do not create layers directly, instead you ask the scene to make one.
It returns the id number of the layer, which can then be used to retrieve the layer type,
or used to send an entity into the correct layer.

Layer is not intended to be extended, there is little behaviour to overload. It simply houses
entities, distributes events to the entities, and keeps track of which entities are subscribed to what events.

```lua
local layerId = scene:makeLayer(1000) -- the parameter is a priority. higher = ran first

-- To retrieve:
local layer = scene:getLayer(layerId)

-- To send an entity there
local entId = scene:makeEntity(PlayerEntity)
local ent = scene:assignEntity(entId, layerId)
-- OR
local ent = scene:quickCreate(PlayerEntity, layerId) -- Same as above
```