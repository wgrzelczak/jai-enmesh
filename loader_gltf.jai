// Unsupported:
// - primitive->mode
// - primitive->targets

#scope_module
load_from_gltf :: (filename : string, opts : Options) -> File_Content, success : bool {
    gltf, success := jason.json_parse_file(filename, Gltf_File);
    
    //
    // Load gltf buffers
    {
        for *gltf.buffers {
            if begins_with(it.uri, "data:application") {
                result, left, right := split_from_left(it.uri, ",");
                view : [] u8;
                view.data  = right.data;
                view.count = right.count;
                
                it.loaded_data = Base64.base64_decode(view);
            } else {
                file, success := file_open(it.uri);
                defer file_close(*file);
                if !success 
	                log_error("Couldn't open bin file: %!", it.uri);
                
                str_data := read_entire_file(file);
                          
                it.loaded_data.data  = str_data.data;
                it.loaded_data.count = str_data.count;
            }
            
            if it.loaded_data.count != it.byteLength {
                log_error("Couldn't load buffer with index : %!", it_index);
            }
        }
    }
    
    //
    // Create File_Content
    f : File_Content;
    f.filename = filename;
    array_resize(*f.meshes, gltf.meshes.count);
    for mesh, mesh_idx : gltf.meshes {
        out_mesh := *f.meshes[mesh_idx];
        out_mesh.name = mesh.name;
        
        array_resize(*out_mesh.primitives, mesh.primitives.count);
        for prim, prim_idx : mesh.primitives {
            out_prim := *out_mesh.primitives[prim_idx];
            //
            // Vertices
            accessors : [..] *Internal_Accessor;
            a_pos, success_pos := init_accessor(gltf, prim.attributes.POSITION);
            a_nor, success_nor := init_accessor(gltf, prim.attributes.NORMAL);
            a_uv0, success_uv0 := init_accessor(gltf, prim.attributes.TEXCOORD_0);
            
            for opts.vertices_attributes_order {
                if it == {
                    case .Position; if success_pos then array_add(*accessors, *a_pos);
                    case .Normal;   if success_nor then array_add(*accessors, *a_nor);
                    case .UV0;      if success_uv0 then array_add(*accessors, *a_uv0);
                }
            }
            if accessors.count == 0 {
                log_error("No vertex accessors!");
                return f, false;
            }
            //TODO(nyv): check if all accessors have the same element_count
            
            vertex_stride : u64 = 0;
            for accessors {
                vertex_stride += it.element_size;
            }
            
            vertices_count := accessors[0].element_count;
            array_resize(*out_prim.vertices, cast(s64)vertex_stride * cast(s64)vertices_count);
            out_data := out_prim.vertices.data;
            
            for v_idx : 0..vertices_count-1 {
                float_size := 4;
                for accessors {
	                eat_and_save(it, out_data, cast(s64)it.element_size);
	                out_data += it.element_size;
                }
            }
                       
            //
            // Indices
            if prim.indices != UNDEFINED {
            	accessor, success := init_accessor(gltf, prim.indices);
            	if !success {
                    log_error("Cannot parse indices of '%'!", mesh.name);
                    return f, false;
                }
                
                out_element_size := opts.indices_element_size_in_bytes;
                array_resize(*out_prim.indices, cast(s64)accessor.element_count* cast(s64)out_element_size);
                
                out_data := out_prim.indices.data;
                for 0..accessor.element_count-1 {
                    eat_and_save(*accessor, out_data, out_element_size);
                    out_data += out_element_size;
                }
            }
        }
    }
    
    
    return f, true;
}

#scope_file
Gltf_File :: struct {
    meshes      : [..] Gltf_Mesh;
    accessors   : [..] Gltf_Accessor;
    bufferViews : [..] Gltf_Buffer_View;
    buffers     : [..] Gltf_Buffer;
}

Gltf_Mesh :: struct {
    name       := UNDEFINED_STR;
    primitives : [..] Gltf_Primitive;
}

Gltf_Primitive :: struct {
    attributes : Gltf_Primitive_Attributes;
    indices    := UNDEFINED;
}

Gltf_Primitive_Attributes :: struct {
    POSITION   := UNDEFINED;
    NORMAL     := UNDEFINED;
    TEXCOORD_0 := UNDEFINED;
    //TODO(nyv): Incomplete
}

Gltf_Accessor :: struct {
    bufferView    := UNDEFINED;
    byteOffset    := 0;
    componentType := UNDEFINED;
    count         := UNDEFINED;
    type          := UNDEFINED_STR;
}

Gltf_Buffer_View :: struct {
    buffer     := UNDEFINED;
    byteLength := UNDEFINED;
    byteOffset := 0;
    byteStride := UNDEFINED;
}

Gltf_Buffer :: struct {
    uri         := UNDEFINED_STR;
    byteLength  := UNDEFINED;
    
    loaded_data : [] u8; @JsonIgnore
}

UNDEFINED :: -1;
UNDEFINED_STR :: "UNDEFINED";

Internal_Accessor :: struct {
    data          : *u8;
    element_size  : u64;
    stride        : u64;
    element_count : u64;
}

init_accessor :: (gltf : Gltf_File, index := UNDEFINED) -> Internal_Accessor, success : bool {
    if index == UNDEFINED {
        return .{}, false;
    }
    
    accessor  : *Gltf_Accessor;
    buff_view : *Gltf_Buffer_View;
    buff      : *Gltf_Buffer;
    success := true;
    //TODO(nyv): Bound checks
    accessor  = *gltf.accessors[index];
    buff_view = *gltf.bufferViews[accessor.bufferView];
    buff      = *gltf.buffers[buff_view.buffer];
    
    ret : Internal_Accessor;
    ret.data          = buff.loaded_data.data;
    ret.data         += accessor.byteOffset + buff_view.byteOffset;
    ret.element_size  = get_element_size(accessor.componentType, accessor.type);
    ret.element_count = cast(u64)accessor.count;
    if buff_view.byteStride != UNDEFINED {
        ret.stride = cast(u64)buff_view.byteStride;
    } else {
	    ret.stride = ret.element_size;
    }
    
    return ret, success;
}

eat_and_save :: (using accessor : *Internal_Accessor, dest : *u8, dest_size : s64) {
    value : u64;
    if element_size == {
        case 1; value = <<cast(*u8) data;
        case 2; value = <<cast(*u16)data;
        case 4; value = <<cast(*u32)data;
        case 8; value = <<cast(*u64)data;
    }
    if dest_size == {
        case 1; << cast(*u8)  dest = cast(u8) value;
        case 2; << cast(*u16) dest = cast(u16)value;
        case 4; << cast(*u32) dest = cast(u32)value;
        case 8; << cast(*u64) dest = cast(u64)value;
        case; {
            if cast(u64)dest_size == element_size {
                memcpy(dest, data, dest_size);
            }
        }
    }
    data += element_size;
}

get_element_size :: (component_type : s64, type : string) -> u64 {
    
    multiplier : u64 = 1;
    if type == {
        case "SCALAR";
        case "VEC2"; multiplier = 2;
        case "VEC3"; multiplier = 3;
        case "VEC4"; multiplier = 4;
        case "MAT2"; multiplier = 4;
        case "MAT3"; multiplier = 9;
        case "MAT4"; multiplier = 16;
        case; log_error("Unknown type '%'!", type);
    }
    
    size : u64 = 0;
    if component_type == {
        case 5120; size = 1; // BYTE
        case 5121; size = 1; // UNSIGNED_BYTE
        case 5122; size = 2; // SHORT
        case 5123; size = 2; // UNSIGNED_SHORT
        case 5125; size = 4; // UNSIGNED_INT
        case 5126; size = 4; // FLOAT32
        case; log_error("Unknown component type '%'!", component_type);
    }
    return size * multiplier;
}

jason :: #import "jason";
Base64 :: #import "Base64_Decode";
#import "String";