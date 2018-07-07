# Tags
On some guilds, people may find themselves often answering the same questions, or simply want to provide resources in an easy-to-request manner.
Bolt's tags feature is built for helping out with this task.


## Commands
### `.tag <name:str...>`
Shows the tag with the given `name` (case-insensitive). If Bolt could not find any tags matching that name, it will display tags with similar names.
```js
// Look up the tag named 'Music'.
.tag music
```

### `.tag create <name:str> <content:str...>`
Create a new tag with the given name and content. The name must be unique on the server.
```js
// Create a tag named 'Music' with a link as content.
.tag create Music www.youtube.com/watch?v=DLzxrzFCyOs

// Create a tag spanning multiple words with a link as content.
.tag create "Radio Ga Ga" www.youtube.com/watch?v=azdwsXLmrHE
```

### `.tag delete <name:str...>`
Deletes the tag with the given name (case-sensitive). Only the tag author can delete the tag.
```js
// Delete the tag named 'Radio Ga Ga'
.tag delete Radio Ga Ga

// Delete the tag named 'Music'
.tag delete Music
```

### `.tag list`
Lists all tags on the current guild.
```js
// Show all tags on the current guild.
.tag list
```

### `.tag raw <name:str...>`
Returns the contents of the tag named `name` (case-insensitive) as a file.
The extension `.md` is used to indicate that it's written in Markdown.
```js
// Get a file with the contents of the 'Music' tag.
.tag raw music
```
