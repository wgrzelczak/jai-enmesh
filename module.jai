Default_Vertex :: struct {
    position : Vector3;
    normal   : Vector3;
    tangent  : Vector4;
    uv0      : Vector2;
}

Options :: struct (VERTEX_TYPE : $Type){
    loader : Loader;
    save_per_primitive := false;
    save_blob          := true;
    
    // Vertices
    vertices_add_missing    := false; //@Incomplete
    vertices_attributes_order : [] Attribute = .[.Position, .Normal, .Tangent, .UV0]; // generate by notes
    vertices_generate_tangents_if_needed := true; // xyz tangent, w flip for binormal
    
    // Indices
    indices_element_size_in_bytes := 2; // -> u16
}

Loader :: enum {
    GLTF;
}

File_Content :: struct {
    filename : string;
    meshes   : [..] Mesh;
    
    tangents_found := false;
}

Mesh :: struct {
    name       : string;
    primitives : [..] Primitive;
}

Primitive :: struct {
    name : string;
    attributes : [..] Attribute;
    vertices : [..] u8;
    indices  : [..] u8;
    
#place vertices; vertices_f32 : [] float32;
}

//TODO(nyv): colors, joints, weights
Attribute :: enum {
    Position;
    Normal;
    Tangent;
    UV0;
    UV1;
}

convert :: (filepath : string, opts := Options(Default_Vertex).{}) {
    content : File_Content = ---;
    success : bool;
    if opts.loader == {
        case .GLTF;    content, success = load_from_gltf(filepath, opts);
    }
    
    if opts.vertices_generate_tangents_if_needed && !content.tangents_found {
        for *m, m_idx : content.meshes {
            for *p, p_idx : m.primitives {
                generate_tangents(opts, *p.vertices, *p.indices);
            }
        }
    }
    
    left  : string;
    right : string;
    success, left, right = split_from_right(content.filename, ".");
    dir := left;
    make_directory_if_it_does_not_exist(dir);
    
    //
    // Save primitives one by one
    if opts.save_per_primitive {
    	for m : content.meshes {
   	     d := tprint("%/%", dir, m.name);
      	  make_directory_if_it_does_not_exist(d);
        	
	        for m.primitives {
	        	write_entire_file(tprint("%/%_vertices.bin", d, it_index), it.vertices.data, it.vertices.count);
            	write_entire_file(tprint("%/%_indices.bin", d, it_index), it.indices.data, it.indices.count);
     	   }
        }
    }
    
    //
    // Save all primitives to one file
    if opts.save_blob {
        file_v := file_open(tprint("%/blob_vertices.bin", dir), true, false);
        file_i := file_open(tprint("%/blob_indices.bin", dir), true, false);
        defer file_close(*file_v);
        defer file_close(*file_i);
        
        info_builder : String_Builder;
        offset_v := 0;
        offset_i := 0;        
        
        //TODO(nyv): add user callbacks for printing, as we dont want to produce csv here
        print_to_builder(*info_builder, "%;%;%;%;%;%;%\n",
                         "mesh_name", "primitive_name", "layout",
                         "v_size_in_bytes", "v_offset_in_bytes",
                         "i_size_in_bytes", "i_offset_in_bytes");
        
        for m : content.meshes {
        	for m.primitives {
	        	print_to_builder(*info_builder, "%;%;%;%;%;%;%\n",
                                 m.name, it.name, it.attributes,
                                 it.vertices.count, offset_v, 
                                 it.indices.count,  offset_i);
                file_write(*file_v, it.vertices.data, it.vertices.count); 
                file_write(*file_i, it.indices.data, it.indices.count); 
                offset_v += it.vertices.count;
                offset_i += it.indices.count;
            }
        }
        
        write_entire_file(tprint("%/info.csv", dir), info_builder);
    }
}

#scope_file

generate_tangents :: (opts : Options, vertices : *[]u8, indices : *[]u8) {
    vertices_view : []opts.VERTEX_TYPE;
    vertices_view.data  = cast(*opts.VERTEX_TYPE)vertices.data;
    vertices_view.count = vertices.count / size_of(opts.VERTEX_TYPE);
    indices_view : []u16;
    indices_view.data  = cast(*u16)indices.data;
    indices_view.count = indices.count / 2; 
    assert(indices_view.count % 3 == 0);
    
    User_Ctx :: struct {
        view_v : []opts.VERTEX_TYPE;
        view_i : []u16;
    };
    
    user_ctx : User_Ctx;
    user_ctx.view_v = vertices_view;
    user_ctx.view_i = indices_view;
    
    inter : SMikkTSpace.SMikkTSpaceInterface;
    inter.m_getNumFaces = (ctx: *SMikkTSpace.SMikkTSpaceContext) -> s32 #c_call {
        user_ctx := cast(*User_Ctx)ctx.m_pUserData;
        return cast(s32)user_ctx.view_v.count / 3;
    };
    inter.m_getNumVerticesOfFace = (ctx: *SMikkTSpace.SMikkTSpaceContext, iFace: s32) -> s32 #c_call {
        // Only triangles supported;
        return 3;
    };
    inter.m_getPosition = (ctx: *SMikkTSpace.SMikkTSpaceContext, out: *float, iFace: s32, iVert: s32) -> void #c_call {
        user_ctx := cast(*User_Ctx)ctx.m_pUserData;
        ii := user_ctx.view_i[3 * iFace + iVert];
        out[0] = user_ctx.view_v[ii].position.x;
        out[1] = user_ctx.view_v[ii].position.y;
        out[2] = user_ctx.view_v[ii].position.z;
    };
    inter.m_getNormal = (ctx: *SMikkTSpace.SMikkTSpaceContext, out: *float, iFace: s32, iVert: s32) -> void #c_call {
        user_ctx := cast(*User_Ctx)ctx.m_pUserData;
        ii := user_ctx.view_i[3 * iFace + iVert];
        out[0] = user_ctx.view_v[ii].normal.x;
        out[1] = user_ctx.view_v[ii].normal.y;
        out[2] = user_ctx.view_v[ii].normal.z;
    };
    inter.m_getTexCoord = (ctx: *SMikkTSpace.SMikkTSpaceContext, out: *float, iFace: s32, iVert: s32) -> void #c_call {
        user_ctx := cast(*User_Ctx)ctx.m_pUserData;
        ii := user_ctx.view_i[3 * iFace + iVert];
        out[0] = user_ctx.view_v[ii].uv0.x;
        out[1] = user_ctx.view_v[ii].uv0.y;
    };
    inter.m_setTSpaceBasic = (ctx: *SMikkTSpace.SMikkTSpaceContext, inTangent: *float, fSign : float, iFace : s32, iVert: s32) -> void #c_call {
        user_ctx := cast(*User_Ctx)ctx.m_pUserData;
        ii := user_ctx.view_i[3 * iFace + iVert];
        user_ctx.view_v[ii].tangent.x = inTangent[0];
        user_ctx.view_v[ii].tangent.y = inTangent[1];
        user_ctx.view_v[ii].tangent.z = inTangent[2];
        user_ctx.view_v[ii].tangent.w = fSign;
    };
    
    ctx   : SMikkTSpace.SMikkTSpaceContext;
    ctx.m_pUserData  = xx *user_ctx;
    ctx.m_pInterface = xx *inter;
    
    result := SMikkTSpace.genTangSpaceDefault(*ctx);
    assert(result == 1);
}








#import "Basic";
#import "File";
#import "Math";
SMikkTSpace :: #import "MikkTSpace";
#load "loader_gltf.jai";