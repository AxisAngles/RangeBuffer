Allows for writing, bits, trits, etc.

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

