When the game client finishes loading the addon, the callback object is automatically initialized. The Esohead
variable is accessible to third party addons, but events are fired to make accessing data easier.

### Esohead:Log
_(**object** nodes, ...)_

Logs any type of data to the Esohead Saved Variables file. Takes an ordered table of strings that define the node
and/or sub-nodes that data will be logged to.

For example
```lua
Esohead:Log({ "chests", "Some Zone", "Some Sub-Zone" }, 0.67, 0.47)
```
Would create an entry in saved variables like this
```lua
Esohead_SavedVariables =
{
    ["Default"] =
    {
        ["@account"] =
        {
            ["CharacterName"] =
            {
                ["Esohead"] =
                {
                    ["chests"] =
                    {
                        ["Some Zone"] =
                        {
                            ["Some Sub-Zone"] =
                            {
                                [1] =
                                {
                                    [1] = 0.67,
                                    [2] = 0.47,
                                },
                            },
                        },
                    },
                },
            },
        },
    },
},
```

## Events
###ESOHEAD_EVENT_TARGET_CHANGED
_returns **string** type, **string** targetName, **float** xPos, **float** yPos, **int** targetLevel_
Provides more targeting data than the EVENT_RETICLE_TARGET_CHANGED event provided by Zenimax (which only fires on NPCs)