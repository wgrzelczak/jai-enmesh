#import "Basic";
Enmesh :: #import "jai-enmesh";

main :: () {
    opts := Enmesh.Options.{
        loader = .GLTF
    };
    Enmesh.convert("plane2.gltf", opts);
}