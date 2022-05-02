Options :: struct {
    loader : Loader;
    
    // Vertices
    vertices_add_missing    := false; //@Incomplete
    vertices_order_position := 0;
    vertices_order_normal   := 1;
    vertices_order_tangent  := 2;
    vertices_order_uv0      := 3;
    vertices_order_uv1      := 4;
    
    //TODO(nyv): colors, joints, weights
    
    
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

convert :: (filepath : string, opts := Options.{}) {
    content : File_Content = ---;
    success : bool;
    if opts.loader == {
        case .GLTF;    content, success = load_from_gltf(filepath, opts);
    }
    
    print("Content: %\n", content);
}

#scope_file
#import "Basic";
#import "File";
#load "loader_gltf.jai";
