# Tag commands
On some guilds, people may find themselves often answering the same questions, or simply want to provide resources in an easy-to-request manner.
Bolt's tags feature is built for helping out with this task.


## `.tag <name:str...>`
Shows the tag with the given `name` (case-insensitive). If bolt could not find any tags matching that name, it will display tags with similar names.
```js
// Look up the tag named 'Music'.
.tag music
```

## `.tag create <name:str> <content:str...>`
Create a new tag with the given name and content. The name must be unique on the server.
Due to the way bolt's command parsing works, tag names spanning multiple words must be surrounded in quotes. This is not necessary for the tag content.
```js
// Create a tag named 'Music' with a link as content.
.tag create Music www.youtube.com/watch?v=DLzxrzFCyOs

// Create a tag spanning multiple words with a link as content.
.tag create "Radio Ga Ga" www.youtube.com/watch?v=azdwsXLmrHE
```

## `.tag delete <name:str...>`
Deletes the tag with the given name (case-sensitive). Only the tag author can delete the tag.
```js
// Delete the tag named 'Radio Ga Ga'
.tag delete Radio Ga Ga

// Delete the tag named 'Music'
.tag delete Music
```

## `.tag list`
Lists all tags on the current guild.
```js
// Show all tags on the current guild.
.tag list
```
