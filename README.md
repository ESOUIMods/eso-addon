## Setup
1.  Go to the ESO documents directory at ```C:\Users\YOURUSER\Documents\Elder Scrolls Online\VERSION\``` (replace VERSION with the client you're using)
2.  If a folder called ``Addons`` doesn't exist, create it.
3.  Clone this repository inside the ```Addons``` folder as ```Esohead```
4.  Load the game, log into character selection and click the ```Add-Ons``` option. You should see ```Esohead Looter``` on your list, please ensure ```Load Out of Date Addons``` is selected if the addon is out of date.
5.  After logging into the game, you should see ```Esohead addon initialized. Debugging is disabled.```

## SavedVariables
After logging into the game and gathering some data, and logging out completely or typing ```/reloadui```, a SavedVariables file may be examined at ```C:\Users\YOURUSER\Documents\Elder Scrolls Online\VERSION\SavedVariables\Esohead.lua```

## Slash Commands
```/esohead reset```
Completely resets all gathered data.

```/esohead reset DATATYPE```
Resets a specific type of data

```/esohead debug on|off```
Toggles verbose addon debugging.

```/esohead datalog```
Displays the total number of each data type the addon has gathered.

```/rl``` & ```/reload```
Aliases of the reloadui command

## Core Functions
**EH.Log** _(**string** type, **object** nodes, ...)_<br />
Logs any type of data to the Esohead Saved Variables file. Takes an ordered table of strings that define the node
and/or sub-nodes that data will be logged to.

For example
```lua
EH.Log("npc", { "Glenumbra", "Covenant Archer" }, 0.67, 0.47)
```
Would create an entry in saved variables like this
```lua
Esohead_SavedVariables =
{
    ["Default"] =
    {
        ["@mdurrant"] =
        {
            ["$AccountWide"] =
            {
                ["npc"] =
                {
                    ["Glenumbra"] =
                    {
                        ["Covenant Archer"] =
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
```
<br />
**EH.LogCheck** _(**string** type, **object** nodes, x, y)_<br />
Checks an ordered table of nodes for an x and y position, returns false if there is an entry that is close to those coordinates.

**EH.NumberFormat** _(**int** number)_<br />
Returns a comma-formatted number string for display to the user.

**EH.Debug** <br />
Displays a message in the chat window containing the output of the data passed to it. Accepts any data type or function.


## API Helpers
**EH.GetUnitPosition** _(**string** unitTag)_<br />
_returns **float** x, **float** y, **float** heading, **string** subZone, **string** world_<br /><br />
Combines 3 API commands and returns all the crucial data to pinpointing a location.