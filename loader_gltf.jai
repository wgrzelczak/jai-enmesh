// Unsupported:
// - primitive->mode
// - primitive->targets

#scope_module
load_gltf :: (filename : string) {
    gltf, success := jason.json_parse_file(filename, Gltf_File);
    print("gltf file: \n%\n", gltf); 
}



#scope_file
jason :: #import "jason";

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
    componentType := UNDEFINED;
    count         := UNDEFINED;
    type          := UNDEFINED_STR;
}

Gltf_Buffer_View :: struct {
    buffer     := UNDEFINED;
    byteLength := UNDEFINED;
    byteOffset := UNDEFINED;
    byteStride := UNDEFINED;
}

Gltf_Buffer :: struct {
    uri        := UNDEFINED_STR;
    byteLength := UNDEFINED;
}

UNDEFINED :: -1;
UNDEFINED_STR :: "UNDEFINED";