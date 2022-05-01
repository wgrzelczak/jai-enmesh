Enmesh_Loader :: enum {
    GLTF;
}

Enmesh_Mesh :: struct {
}

Enmesh_Vertex_Layout :: struct {
    
}


enmesh :: (filepath : string, loader : Enmesh_Loader = .GLTF) {
    if loader == {
        case .GLTF;
        load_gltf(filepath);
    }
    
    
}

#scope_file
#import "Basic";
#import "File";
#load "loader_gltf.jai";
