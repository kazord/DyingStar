extends Camera3D

var filepath = "user://record.avi"
var fps = 60

var _file
var _frames = 1

var _recording = false
var _idx = PackedByteArray()
var _idx_offset = 4
var _frame_delay = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('game_record') && !_recording:
		print("start recording")
		start_recording()
	elif event.is_action_pressed('game_record') && _recording:
		print("stop recording")
		stop_recording()

func is_recording():
	return _recording
	
func start_recording():
	_file = FileAccess.open(filepath, FileAccess.WRITE)
	if _file == null:
		return
	var img = get_viewport().get_texture().get_image().save_jpg_to_buffer()
	index_chunk(img.size())
	
	var headers = PackedByteArray()
	headers.append_array(header_avi())
	headers.append_array(main_avi_header(fps, _frames, get_window().size.x, get_window().size.y)) #fps, frame, width, height
	headers.append_array(video_stream_list())
	headers.append_array(video_stream_header(fps, get_window().size.x, get_window().size.y, _frames))
	var data = header_list(headers)
	video_stream_data_header(data, img)
	data.append_array(video_stream_data(img))
	#actual write on file
	_file.store_buffer(riff_header(data))
	_recording = true
	
func _process(delta: float) -> void:
	if _recording && (_frame_delay+delta > (1.0/fps)):
		update_video()
		_frame_delay = 0.0
	else:
		_frame_delay += delta
		
func stop_recording():
	if _file == null || _recording == false:
		return
	_recording = false
	_file.seek_end()
	_file.store_buffer(make_index(_idx))
	var buffer_size = _file.get_position()
	_file.seek(4)
	int4store_le(_file, buffer_size-8)
	_file.close()

func update_video():
	_frames += 1
	var img = get_viewport().get_texture().get_image().save_jpg_to_buffer()
	var imgbuffer = video_stream_data(img)
	_file.seek_end()
	_file.store_buffer(imgbuffer)
	var buffer_size = _file.get_position()
	#update riff size
	_file.seek(4)
	int4store_le(_file, buffer_size-8)
	#frames
	_file.seek(48)
	int4store_le(_file, _frames)
	_file.seek(140)
	int4store_le(_file, _frames)
	#datasize
	_file.seek(2052)
	int4store_le(_file,buffer_size-2048-8)
	
	index_chunk(img.size())
	
func int4bytes_le(num):
	return [num&0xFF, (num&0xFF00)>>8, (num&0xFF0000)>>16, (num&0xFF000000)>>24]
	
func int2bytes_le(num):
	return [num&0xFF, (num&0xFF00)>>8]
	
func int4store_le(file, num):
	file.store_8(num&0xFF)
	file.store_8((num&0xFF00)>>8)
	file.store_8((num&0xFF0000)>>16)
	file.store_8((num&0xFF000000)>>24)
	
func riff_header(data):
	var buffer = PackedByteArray()
	#0 RIFF ID
	buffer.append_array([0x52, 0x49, 0x46, 0x46])
	#4 file size - 8 (little iendian)
	buffer.append_array(int4bytes_le(data.size()-8))
	#8 Format
	buffer.append_array([0x41, 0x56, 0x49, 0x20])
	buffer.append_array(data)
	return buffer

func header_list(headers):
	var buffer = PackedByteArray()
	#12 LIST
	buffer.append_array([0x4c, 0x49, 0x53, 0x54])
	#16 Length header size 
	buffer.append_array(int4bytes_le(headers.size()+4))
	#20 header id : hdrl
	buffer.append_array([0x68, 0x64, 0x72, 0x6c])
	#inc headers
	buffer.append_array(headers)
	return buffer

func header_avi():
	var buffer = PackedByteArray()
	#24 avih
	buffer.append_array([0x61, 0x76, 0x69, 0x68])
	#28 Length header size 
	buffer.append_array([0x38, 00, 00, 00])
	return buffer

func main_avi_header(framepersec, nb_frames, width, height):
	var buffer = PackedByteArray()
	#32 microsec per frame 
	#buffer.append_array(int4bytes_le(60000000/fps))# 2 000 000 = [0x80, 0x84, 0x1e, 0x00])
	buffer.append_array(int4bytes_le(int(1.0 / framepersec * 1000 * 1000)))
	#36 Max byte rate ffmpeg 25000
	buffer.append_array(int4bytes_le(25000))
	#40 Reserved
	buffer.append_array([00, 00, 00, 00])
	#44 FLAGS
	buffer.append_array([0x10, 0x08, 00, 00])
	#buffer.append_array([0x0, 0x0, 00, 00])
	#48 Total Frames
	buffer.append_array(int4bytes_le(nb_frames))
	#52 Init Frames
	buffer.append_array([0, 0, 0, 0])
	#56 Nb Streams
	buffer.append_array([0x01, 0x00, 0, 0])
	#60 Suggested buffer
	buffer.append_array([0x00, 0x00, 0x10, 0x00])
	#64 width in pix
	buffer.append_array(int4bytes_le(width))# 1920 =[0x80, 0x07, 0x00, 0x00]) 
	#68 height in pix
	buffer.append_array(int4bytes_le(height))# 1080 = [0x38, 0x04, 0x00, 0x00])
	# 72 Reserve
	buffer.append_array([0, 0, 0, 0])
	buffer.append_array([0, 0, 0, 0])
	buffer.append_array([0, 0, 0, 0])
	buffer.append_array([0, 0, 0, 0])
	return buffer

func video_stream_list():
	var buffer = PackedByteArray()
	#88 LIST
	buffer.append_array([0x4c, 0x49, 0x53, 0x54])
	#92 LIST SIZE
	buffer.append_array([0x74, 0, 0, 0])
	#96 stream list
	buffer.append_array([0x73, 0x74, 0x72, 0x6C])
	#100 stream header
	buffer.append_array([0x73, 0x74, 0x72, 0x68])
	#104 length
	buffer.append_array([0x38, 0, 0, 0])
	return buffer
	
func video_stream_header(framepersec, width, height, frames):
	var buffer = PackedByteArray()
	#108 Type vids
	buffer.append_array([0x76, 0x69, 0x64, 0x73])
	#112 Handler FourCC
	buffer.append_array([0x6d, 0x6a, 0x70, 0x67]) #mj2c [0x6d, 0x6a, 0x32, 0x63])
	#116 Flags
	buffer.append_array([0, 0, 0, 0])
	#120 Priority + language
	buffer.append_array([0, 0, 0, 0])
	#124 Init frame
	buffer.append_array([0, 0, 0, 0])
	#128 scale
	buffer.append_array(int4bytes_le(1000*1000))
	#132 rate
	buffer.append_array(int4bytes_le(int(framepersec*1000*1000)))
	#136 Start
	buffer.append_array([0, 0, 0, 0])
	#140 length
	buffer.append_array(int4bytes_le(frames))
	#144 buffer size
	buffer.append_array([0x00, 0x00, 0x00, 0x00])
	#148 Quality
	buffer.append_array(int4bytes_le(-1))
	#152 Sample Size
	buffer.append_array([0, 0, 0, 0])
	#156 Frame
	#buffer.append_array([0, 0, 0, 0, 0x80, 0x07, 0x38, 0x04])
	buffer.append_array([0, 0, 0, 0])
	buffer.append_array(int2bytes_le(width))
	buffer.append_array(int2bytes_le(height))
	#buffer.append_array([0, 0, 0, 0])
	#--- stream format
	#164 Stream format
	buffer.append_array([0x73, 0x74, 0x72, 0x66])
	#168 Length
	buffer.append_array([0x28, 0, 0, 0])
	#func write_video_stream_format(buffer):
	#172 Length
	buffer.append_array([0x28, 0, 0, 0])
	#176 width in pix
	buffer.append_array(int4bytes_le(width)) 
	#180 height in pix
	buffer.append_array(int4bytes_le(height))
	#184 Planes
	buffer.append_array([0x01, 0x00])
	#186 Bit count = 24
	buffer.append_array([0x18, 0x0])
	#188 Compression (BI_RGB, BI_RLE8, BI_RLE4, BI_BITFIELDS, BI_JPEG, BI_PNG)
	buffer.append_array([0x6d, 0x6a, 0x70, 0x67])
	#192 Image Size (bytes)
	#buffer.append_array(int4bytes_le(height * ((3 * width + 3) / 4) * 4))
	buffer.append_array([0,0,0,0])
	#196 Image X pixel per meter
	buffer.append_array([0,0,0,0])
	#200 Image Y pixel per meter
	buffer.append_array([0,0,0,0])
	#204 Image Clr used
	buffer.append_array([0,0,0,0])
	#208 Colors Important
	buffer.append_array([0,0,0,0])
	return buffer
	
func video_stream_data_header(buffer, data):
	#Junk to 2036
	buffer.append_array([0x4a, 0x55, 0x4e, 0x4b])
	#size to 2036
	buffer.append_array(int4bytes_le(2032-buffer.size()))
	buffer.resize(2036)
	#---
	#2036 LIST
	buffer.append_array([0x4c, 0x49, 0x53, 0x54])
	#2040 LIST SIZE
	buffer.append_array(int4bytes_le(data.size()+4))
	#2044 stream tag mj2c
	#buffer.append_array([0x6d, 0x6a, 0x32, 0x63])
	#movi
	buffer.append_array([0x6d, 0x6f, 0x76, 0x69])
	return buffer
	
func video_stream_data(data):
	var buffer = PackedByteArray()
	#- datatype ##dc for compressed
	buffer.append_array([0x30, 0x30, 0x64, 0x63])
	#-data size
	buffer.append_array(int4bytes_le(data.size()))
	#-frame data
	buffer.append_array(data)
	if(buffer.size()%2 != 0):
		buffer.append_array([0x00])
	return buffer
	
func make_index(data):
	var buffer = PackedByteArray()
	#idx1
	buffer.append_array([0x69, 0x64, 0x78, 0x31])
	#size
	buffer.append_array(int4bytes_le(data.size()))
	buffer.append_array(data)
	return buffer
	
func index_chunk(length):
	#fourcc
	_idx.append_array([0x30, 0x30, 0x64, 0x63])
	#AVIkeyFRAME
	_idx.append_array([0x10, 0x00, 0x00, 0x00])
	#offset
	_idx.append_array(int4bytes_le(_idx_offset))
	#length
	
	_idx.append_array(int4bytes_le(length))
	if(length%2 != 0):
		length+=1
	_idx_offset += 8 + length
