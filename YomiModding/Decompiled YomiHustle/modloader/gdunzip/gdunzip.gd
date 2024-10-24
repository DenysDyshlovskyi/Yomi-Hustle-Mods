





















































var path


var buffer


var buffer_size










var files = {}


var pos = 0



var tinf


func _init():
	self.tinf = Tinf.new()


func load(path):
	if path == null:
		return false

	self.path = path
	self.pos = 0

	var file = File.new()

	if not file.file_exists(path):
		return false

	file.open(path, File.READ)
	var file_length = file.get_len()
	if file.get_32() != 67324752:
		return false

	file.seek(0)
	self.buffer = file.get_buffer(file_length)
	self.buffer_size = self.buffer.size()
	file.close()

	if self.buffer_size < 22:
		
		return false

	
	return self._get_files()





func uncompress(file_name):
	if not (file_name in self.files):
		return false

	var f = self.files[file_name]
	self.pos = f["file_header_offset"]
	self._skip_file_header()
	var uncompressed = self._read(f["compressed_size"])
	if f["compression_method"] == - 1:
		return uncompressed
	return tinf.tinf_uncompress(f["uncompressed_size"], uncompressed)



func get_compressed(file_name):
	if not (file_name in self.files):
		return false

	var f = self.files[file_name]
	self.pos = f["file_header_offset"]
	self._skip_file_header()
	return self._read(f["compressed_size"])



func _get_files():
	
	var eocd_offset = buffer.size() - 22

	while (
		eocd_offset > 0
		 and not (buffer[eocd_offset + 3] == 6
			 and buffer[eocd_offset + 2] == 5
			 and buffer[eocd_offset + 1] == 75
			 and buffer[eocd_offset] == 80
		)
	):
		eocd_offset -= 1

	
	self.pos = (
		buffer[eocd_offset + 19] << 24
		 | buffer[eocd_offset + 18] << 16
		 | buffer[eocd_offset + 17] << 8
		 | buffer[eocd_offset + 16]
	)

	
	
	while (
		buffer[pos + 3] == 2
		 and buffer[pos + 2] == 1
		 and buffer[pos + 1] == 75
		 and buffer[pos] == 80
	):
		var raw = _read(46)
		var header = {
			"compression_method": "", 
			"file_name": "", 
			"compressed_size": 0, 
			"uncompressed_size": 0, 
			"file_header_offset": - 1, 
		}

		if raw[10] == 0 and raw[11] == 0:
			header["compression_method"] = - 1
		else :
			header["compression_method"] = File.COMPRESSION_DEFLATE

		header["compressed_size"] = (
			raw[23] << 24
			 | raw[22] << 16
			 | raw[21] << 8
			 | raw[20]
		)

		header["uncompressed_size"] = (
			raw[27] << 24
			 | raw[26] << 16
			 | raw[25] << 8
			 | raw[24]
		)

		header["file_header_offset"] = (
				raw[45] << 24
			 | raw[44] << 16
			 | raw[43] << 8
			 | raw[42]
		)

		var file_name_length = raw[29] << 8 | raw[28]
		var extra_field_length = raw[31] << 8 | raw[30]
		var comment_length = raw[33] << 8 | raw[32]

		var raw_end = _read(file_name_length + extra_field_length + comment_length)
		if not raw_end:
			return false

		header["file_name"] = (
			raw_end.subarray(0, file_name_length - 1).get_string_from_utf8()
		)
		self.files[header["file_name"]] = header

	return true



func _read(length):
	var result = buffer.subarray(pos, pos + length - 1)
	if result.size() != length:
		return false
	pos = pos + length
	return result


func _skip(length):
	pos += length



func _skip_file_header():
	var raw = _read(30)
	if not raw:
		return false

	var file_name_length = raw[27] << 8 | raw[26]
	var extra_field_length = raw[29] << 8 | raw[28]

	var raw_end = _skip(file_name_length + extra_field_length)









class Tinf:
	
	
	
	func make_pool_int_array(size):
		var pool_int_array = PoolIntArray()
		pool_int_array.resize(size)
		return pool_int_array

	func make_pool_byte_array(size):
		var pool_byte_array = PoolByteArray()
		pool_byte_array.resize(size)
		return pool_byte_array

	
	
	

	var TINF_TREE = {
		"table": make_pool_int_array(16), 
		"trans": make_pool_int_array(288), 
	}

	var TINF_DATA = {
		"source": PoolByteArray(), 
		
		
		"sourcePtr": 0, 

		"tag": 0, 
		"bitcount": 0, 

		"dest": PoolByteArray(), 
		"destLen": 0, 

		
		"destPtr": 0, 

		"ltree": TINF_TREE.duplicate(), 
		"dtree": TINF_TREE.duplicate()
	}

	const TINF_OK = 0
	const TINF_DATA_ERROR = - 3

	
	
	

	var sltree = TINF_TREE.duplicate()
	var sdtree = TINF_TREE.duplicate()

	var base_tables = {
		
		"length_bits": make_pool_byte_array(30), 
		"length_base": make_pool_int_array(30), 

		
		"dist_bits": make_pool_byte_array(30), 
		"dist_base": make_pool_int_array(30)
	}

	var clcidx = PoolByteArray([
				16, 17, 18, 0, 8, 7, 9, 6, 
				10, 5, 11, 4, 12, 3, 13, 2, 
				14, 1, 15])

	
	
	

	
	
	
	
	
	func tinf_build_bits_base(target, delta, first):
		var sum = first

		for i in range(0, delta):
			base_tables[target + "_bits"][i] = 0

		for i in range(0, 30 - delta):
			base_tables[target + "_bits"][i + delta] = i / delta

		for i in range(0, 30):
			base_tables[target + "_base"][i] = sum
			sum += 1 << base_tables[target + "_bits"][i]

	
	
	
	func tinf_build_fixed_trees(lt, dt):
		for i in range(0, 7):
			lt["table"][i] = 0

		lt["table"][7] = 24
		lt["table"][8] = 152
		lt["table"][9] = 112

		for i in range(0, 24):
			lt["trans"][i] = 256 + i
		for i in range(0, 144):
			lt["trans"][24 + i] = i
		for i in range(0, 8):
			lt["trans"][24 + 144 + i] = 280 + i
		for i in range(0, 112):
			lt["trans"][24 + 144 + 8 + i] = 144 + i

		for i in range(0, 5):
			dt["table"][i] = 0

		dt["table"][5] = 32

		for i in range(0, 32):
			dt["trans"][i] = i

	
	
	
	
	func tinf_build_tree(t, lengths, num):
		var offs = make_pool_int_array(16)
		var sum = 0

		
		for i in range(0, 16):
			t["table"][i] = 0

		
		for i in range(0, num):
			t["table"][lengths[i]] += 1

		t["table"][0] = 0

		for i in range(0, 16):
			offs[i] = sum
			sum += t["table"][i]

		for i in range(0, num):
			if lengths[i]:
				t["trans"][offs[lengths[i]]] = i
				offs[lengths[i]] += 1

	
	
	

	
	
	
	func tinf_getbit(d):
		var bit = 0

		d["bitcount"] -= 1
		if not (d["bitcount"] + 1):
			d["tag"] = d["source"][d["sourcePtr"]]
			d["sourcePtr"] += 1
			d["bitcount"] = 7

		bit = d["tag"] & 1
		d["tag"] >>= 1
		return bit


	
	
	
	
	func tinf_read_bits(d, num, base):
		var val = 0

		if num:
			var limit = 1 << num
			var mask = 1

			while mask < limit:
				if tinf_getbit(d):
					val += mask
				mask *= 2

		return val + base

	
	
	
	func tinf_decode_symbol(d, t):
		var sum = 0
		var cur = 0
		var length = 0

		while true:
			cur = 2 * cur + tinf_getbit(d)
			length += 1
			sum += t["table"][length]
			cur -= t["table"][length]
			if cur < 0:
				break
		return t["trans"][sum + cur]

	
	
	
	
	func tinf_decode_trees(d, lt, dt):
		var code_tree = TINF_TREE.duplicate()
		var lengths = make_pool_byte_array(288 + 32)
		var hlit = 0
		var hdist = 0
		var hclen = 0
		var num = 0
		var length = 0

		
		hlit = tinf_read_bits(d, 5, 257)

		
		hdist = tinf_read_bits(d, 5, 1)

		
		hclen = tinf_read_bits(d, 4, 4)

		for i in range(0, 19):
			lengths[i] = 0

		for i in range(0, hclen):
			var clen = tinf_read_bits(d, 3, 0)
			lengths[clcidx[i]] = clen

		
		tinf_build_tree(code_tree, lengths, 19)

		while num < hlit + hdist:
			var sym = tinf_decode_symbol(d, code_tree)

			match sym:
				16:
					var prev = lengths[num - 1]
					length = tinf_read_bits(d, 2, 3)
					while length != 0:
						lengths[num] = prev
						num += 1
						length -= 1
				17:
					length = tinf_read_bits(d, 3, 3)
					while length != 0:
								lengths[num] = 0
								num += 1
								length -= 1
				18:
					length = tinf_read_bits(d, 7, 11)
					while length != 0:
						lengths[num] = 0
						num += 1
						length -= 1
				_:
					lengths[num] = sym
					num += 1

		
		tinf_build_tree(lt, lengths, hlit)
		tinf_build_tree(dt, lengths.subarray(hlit, lengths.size() - 1), hdist)

	
	
	

	
	
	
	
	func tinf_inflate_block_data(d, lt, dt):
		var start = d["destPtr"]
		var dest = d["dest"]

		while true:
			var sym = tinf_decode_symbol(d, lt)

			if sym == 256:
				d["destLen"] += d["destPtr"] - start
				d["dest"] = dest
				return TINF_OK

			if sym < 256:
				dest[d["destPtr"]] = sym
				d["destPtr"] += 1
			else :
				var length = 0
				var dist = 0
				var offs = 0
				var ptr = d["destPtr"]

				sym -= 257

				length = tinf_read_bits(d, base_tables["length_bits"][sym], base_tables["length_base"][sym])
				dist = tinf_decode_symbol(d, dt)

				
				offs = tinf_read_bits(d, base_tables["dist_bits"][dist], base_tables["dist_base"][dist])

				for i in range(0, length):
					dest[ptr + i] = dest[ptr + (i - offs)]

				d["destPtr"] += length
		d["dest"] = dest

	
	
	func tinf_inflate_uncompressed_block(d):
		var length = 0
		var invlength = 0
		var i = 0

		
		length = d["source"][d["sourcePtr"] + 1]
		length = 256 * length + d["source"][d["sourcePtr"]]

		
		invlength = d["source"][d["sourcePtr"] + 3]
		invlength = 256 * invlength + d["source"][d["sourcePtr"] + 2]

		if length != ~ invlength & 65535:
			return TINF_DATA_ERROR

		d["sourcePtr"] += 4

		i = length
		while i:
			d["dest"][d["destPtr"]] = d["source"][d["sourcePtr"]]
			d["destPtr"] += 1
			d["sourcePtr"] += 1
			i -= 1

		d["bitcount"] = 0
		d["destLen"] += length

		return TINF_OK


	
	
	
	func tinf_inflate_fixed_block(d):
		
		return tinf_inflate_block_data(d, sltree, sdtree)


	
	
	
	func tinf_inflate_dynamic_block(d):
		
		tinf_decode_trees(d, d["ltree"], d["dtree"])

		
		return tinf_inflate_block_data(d, d["ltree"], d["dtree"])

	
	
	

	func _init():
				
				tinf_build_fixed_trees(sltree, sdtree)

				
				tinf_build_bits_base("length", 4, 3)
				tinf_build_bits_base("dist", 2, 1)

				
				base_tables["length_bits"][28] = 0
				base_tables["length_base"][28] = 258


	
	func tinf_uncompress(destLen, source):
		var d = TINF_DATA.duplicate()
		var dest = make_pool_byte_array(destLen)
		var sourceSize = source.size()
		d["source"] = source
		d["dest"] = dest

		destLen = 0

		while true:
			var btype = 0
			var res = 0

			
			tinf_getbit(d)

			
			btype = tinf_read_bits(d, 2, 0)
			match btype:
				0:
					
					res = tinf_inflate_uncompressed_block(d)
				1:
					
					res = tinf_inflate_fixed_block(d)
				2:
					
					res = tinf_inflate_dynamic_block(d)
				_:
					return false

			if res != TINF_OK:
				return false

			
			if d["sourcePtr"] >= sourceSize:
				break

		return d["dest"]
