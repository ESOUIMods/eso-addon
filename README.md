When the game client finishes loading the addon, the callback object is automatically initialized. The Esohead
variable is accessible to third party addons, but events are fired to make accessing data easier.

## Setup
1.  Go to the ESO documents directory at ```C:\Users\YOURUSER\Documents\Elder Scrolls Online\VERSION\``` (replace VERSION with the client you're using)
2.  If a folder called ``Addons`` doesn't exist, create it.
3.  Clone this repository inside the ```Addons``` folder as ```Esohead```
4.  Load the game, log into character selection and click the ```Add-Ons``` option. You should see ```Esohead Looter``` on your list, please ensure ```Load Out of Date Addons``` is selected if the addon is out of date.
5.  After logging into the game, you should see ```Esohead addon initialized. Debugging is enabled.```

## SavedVariables
After logging into the game and gathering some data, and logging out completely or typing ```/reloadui```, a SavedVariables file may be examined at ```C:\Users\YOURUSER\Documents\Elder Scrolls Online\VERSION\SavedVariables\Esohead.lua```

## Slash Commands
```/esohead reset```
Completely resets all gathered data.

```/esohead debug on|off```
Toggles verbose addon debugging.

```/esohead datalog```
Displays the total number of each data type the addon has gathered.

## Core Functions
**Esohead:Log** _(**object** nodes, ...)_<br />
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
<br />
**Esohead:LogCheck** _(**object** nodes, x, y)_<br />
Checks an ordered table of nodes for an x and y position, returns false if there is an entry that is close to those coordinates.

**Esohead:NumberFormat** _(**int** number)_<br />
Returns a comma-formatted number string for display to the user.

**Esohead:Debug** <br />
Displays a message in the chat window containing the output of the data passed to it. Accepts any data type or function.


## API Helpers
**Esohead:GetUnitPosition** _(**string** unitTag)_<br />
_returns **float** x, **float** y, **float** heading, **string** subZone, **string** world_<br /><br />
Combines 3 API commands and returns all the crucial data to pinpointing a location.


## Events
**ESOHEAD_EVENT_TARGET_CHANGED**<br />
_returns **string** type, **string** targetName, **float** xPos, **float** yPos, **int** targetLevel_

Offers more targeting data than the event provided by Zenimax (which only fires on NPCs)