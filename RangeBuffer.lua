-- By Trey Reynolds (AxisAngle)
--!native
--!strict

local RangeBuffer = {}

local RangeWriter = {} :: RangeWriterMeta
RangeWriter.__index = RangeWriter

local RangeReader = {} :: RangeReaderMeta
RangeReader.__index = RangeReader

-- because we truncate at 48 bits
local max = 2^48

function RangeBuffer.newWriter(): RangeWriterObj
	local self = setmetatable({}, RangeWriter)

	self._size = 6
	self._head = 0
	self._buffers = {}
	self._buffer = buffer.create(self._size)

	self._c = 1
	self._v = 0

	--self._bitLoss = 0

	return self
end

function RangeBuffer.newReader(buff): RangeReaderObj
	local self = setmetatable({}, RangeReader)

	self._size = buffer.len(buff)
	self._head = 0
	self._buffer = buff

	self._c = 1
	self._v = self:_readBuffer48()

	return self
end

function RangeWriter:_writeBuffer48(v)
	if self._head == self._size then
		self._size *= 2
		self._head = 0
		table.insert(self._buffers, self._buffer)
		self._buffer = buffer.create(self._size)
	end

	buffer.writeu32(self._buffer, self._head    , v      ) -- does the modulus for us
	buffer.writeu16(self._buffer, self._head + 4, v//2^32)
	self._head += 6
end

-- n is the number of options, v is the value, v < n
function RangeWriter:write(n, v)
	while n*self._c > max do
		-- factor0 * factor1 >= n
		local f0 = max//self._c
		local f1 = -(-n//f0)
		--self._bitLoss += math.log(max*f1/(self._c*n), 2)
		self:_writeBuffer48(self._v + self._c*(v%f0))
		self._v = 0
		self._c = 1
		n = f1
		v = v//f0
	end

	self._v += self._c*v
	self._c *= n
end

function RangeWriter:dump()
	local length = self._head
	local c = 1
	while c < self._c do
		length += 1
		c *= 256
	end

	for _, buff in next, self._buffers do
		length += buffer.len(buff)
	end

	local offset = 0
	local finalBuff = buffer.create(length)
	for _, buff in next, self._buffers do
		buffer.copy(finalBuff, offset, buff, 0)
		offset += buffer.len(buff)
	end

	buffer.copy(finalBuff, offset, self._buffer, 0, self._head)
	offset += self._head
	
	local v = self._v
	for i = offset, length - 1 do
		buffer.writeu8(finalBuff, i, v)
		v //= 256
	end
	
	return finalBuff
end

function RangeReader:_readBuffer48()
	self._head += 6
	
	if self._head > self._size then
		local v = 0
		local c = 1
		for i = self._head - 6, self._size - 1 do
			local vi = buffer.readu8(self._buffer, i)
			v += c*vi
			c *= 256
		end
		return v
	end
	
	local v0  = buffer.readu32(self._buffer, self._head - 6)
	local v32 = buffer.readu16(self._buffer, self._head - 2)
	local v = v0 + 2^32*v32

	return v
end

-- n is the number of options
function RangeReader:read(n)
	local v = 0
	local c = 1
	-- c goes up as we read
	while n*self._c > max do
		-- factor0 * factor1 >= n
		local f0 = max//self._c
		local f1 = -(-n//f0)
		v += c*self._v
		c *= f0
		n = f1
		self._v = self:_readBuffer48()
		self._c = 1
	end

	v += c*(self._v%n)
	self._v //= n
	self._c *= n

	return v
end


-- I hope this makes it faster
type RangeWriterMeta = {
	__index: RangeWriterMeta;
	_writeBuffer48: (self: RangeWriterObj, v: number) -> ();
	write: (self: RangeWriterObj, range: number, value: number) -> ();
	dump: (self: RangeWriterObj) -> buffer;
}

type RangeWriterObj = typeof(setmetatable({} :: {
	_size: number;
	_head: number;
	_buffers: {[number]: buffer;};
	_buffer: buffer;
	_c: number;
	_v: number;
}, {} :: RangeWriterMeta))

type RangeReaderMeta = {
	__index: RangeReaderMeta;
	_readBuffer48: (self: RangeReaderObj) -> number;
	read: (self: RangeReaderObj, range: number) -> number;
}

type RangeReaderObj = typeof(setmetatable({} :: {
	_size: number;
	_head: number;
	_buffer: buffer;
	_c: number;
	_v: number;
}, {} :: RangeReaderMeta))

return RangeBuffer
