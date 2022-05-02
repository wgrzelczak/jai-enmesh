Options :: struct {
    loader : Loader;
    save_per_primitive := false;
    save_blob          := true;
    
    // Vertices
    vertices_add_missing    := false; //@Incomplete
    vertices_attributes_order : [] Attribute = .[.Position, .Normal, .UV0];  
    
    // Indices
    indices_element_size_in_bytes := 2; // -> u16
}

Loader :: enum {
    GLTF;
}

File_Content :: struct {
    filename : string;
    meshes   : [..] Mesh;
}

Mesh :: struct {
    name       : string;
    primitives : [..] Primitive;
}

Primitive :: struct {
    name : string;
    vertices : [..] u8;
    indices  : [..] u8;
    
#place vertices; vertices_f32 : [] float32;
#place indices; indices_u16   : [] u16;
}

//TODO(nyv): colors, joints, weights, bitangent?
Attribute :: enum {
    Position;
    Normal;
    Tangent;
    UV0;
    UV1;
}

convert :: (filepath : string, opts := Options.{}) {
    content : File_Content = ---;
    success : bool;
    if opts.loader == {
        case .GLTF;    content, success = load_from_gltf(filepath, opts);
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
        print_to_builder(*info_builder, "%;%;%;%;%;%\n",
                         "mesh", "primitive",
                         "v_size_in_bytes", "v_offset_in_bytes",
                         "i_size_in_bytes", "i_offset_in_bytes");
        
        for m : content.meshes {
        	for m.primitives {
	        	print_to_builder(*info_builder, "%;%;%;%;%;%\n",
                                 m.name, it.name,
                                 it.vertices.count, offset_v, 
                                 it.indices.count,  offset_i);
                file_write(*file_v, it.vertices.data, it.vertices.count); 
                file_write(*file_i, it.indices.data, it.indices.count); 
                offset_v += it.vertices.count;
                offset_i += it.indices.count;
            }
        }
        
        write_entire_file(tprint("%/%_info.csv", dir, dir), info_builder);
    }
    
    print("Content: %\n", content);
}

#scope_file
#import "Basic";
#import "File";
#load "loader_gltf.jai";
