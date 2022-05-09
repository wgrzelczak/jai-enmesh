#import "Basic";
Enmesh :: #import "jai-enmesh";

main :: () {
    opts := Enmesh.Options(Enmesh.Default_Vertex).{
        loader = .GLTF
    };
    Enmesh.convert("plane2.gltf", opts);
    //Enmesh.convert("Duck.gltf", opts);
    //Enmesh.convert("busterDrone.gltf", opts);
    Enmesh.convert("DamagedHelmet.gltf", opts);
}