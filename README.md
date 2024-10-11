Allows for writing, bits, trits, etc.

Compared to BitBuffer:  
Backwards compatible  
More memory efficient  
Equally performant  
Easier to use

Basic use:
```lua
local writer = RangeBuffer.newWriter()

writer:write(2, 0) -- write some bits
writer:write(2, 1)
writer:write(3, 0) -- now write some trits
writer:write(3, 1)

local data = writer:dump()

-- make the reader
local reader = RangeBuffer.newReader(data)

print(reader:read(2)) -- read some bits
print(reader:read(2))
print(reader:read(3)) -- read some trits
print(reader:read(3))
```

Example use case: Writing ASCII text.
```lua
 --typical ASCII text is always in the range 32 - 126
 --That is, there are 95 (126 - 32 + 1) possible characters
 --If we don't want to encode the length of the text up front, we can include an extra end-of-stream character as character 95

local function encodeAsciiText(text)
	local writer = RangeBuffer.newWriter()
	for i = 1, #text do
		local token = string.byte(text, i) - 32
		writer:write(96, token)
	end
	writer:write(96, 95) -- end of stream
	local data = writer:dump()
	return data
end

local function decodeAsciiText(data)
	local reader = RangeBuffer.newReader(data)
	local text = ""
	while true do
		local token = reader:read(96)
		if token == 95 then
			break
		end
		text ..= string.char(token + 32)
	end
	return text
end
```
Running the code
```lua
local text = "123 eyes on me, hello world!"
local data = encodeAsciiText(text)
local reconstructedText = decodeAsciiText(data)
print(#text, text)
print(buffer.len(data), reconstructedText)
```
results in
```
> 28 123 eyes on me, hello world!
> 24 123 eyes on me, hello world!
```
So where you might encode a length at the beginning as 2 bytes, ultimately leaving you with 30 bytes,
in this case, we use 24 bytes to enocode the whole string including the length.
It's not a lot of savings, but it was free.
