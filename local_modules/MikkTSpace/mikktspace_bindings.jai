//
// This file was auto-generated using the following command:
//
// 
//



/* Author: Morten S. Mikkelsen
* Version: 1.0
*
* The files mikktspace.h and mikktspace.c are designed to be
* stand-alone files and it is important that they are kept this way.
* Not having dependencies on structures/classes/libraries specific
* to the program, in which they are used, allows them to be copied
* and used as is into any tool, program or plugin.
* The code is designed to consistently generate the same
* tangent spaces, for a given mesh, in any tool in which it is used.
* This is done by performing an internal welding step and subsequently an order-independent evaluation
* of tangent space for meshes consisting of triangles and quads.
* This means faces can be received in any order and the same is true for
* the order of vertices of each face. The generated result will not be affected
* by such reordering. Additionally, whether degenerate (vertices or texture coordinates)
* primitives are present or not will not affect the generated results either.
* Once tangent space calculation is done the vertices of degenerate primitives will simply
* inherit tangent space from neighboring non degenerate primitives.
* The analysis behind this implementation can be found in my master's thesis
* which is available for download --> http://image.diku.dk/projects/media/morten.mikkelsen.08.pdf
* Note that though the tangent spaces at the vertices are generated in an order-independent way,
* by this implementation, the interpolated tangent space is still affected by which diagonal is
* chosen to split each quad. A sensible solution is to have your tools pipeline always
* split quads by the shortest diagonal. This choice is order-independent and works with mirroring.
* If these have the same length then compare the diagonals defined by the texture coordinates.
* XNormal which is a tool for baking normal maps allows you to write your own tangent space plugin
* and also quad triangulator plugin.
*/
tbool :: s32;

SMikkTSpaceInterface :: struct {
    // Returns the number of faces (triangles/quads) on the mesh to be processed.
    m_getNumFaces:          #type (a0: *SMikkTSpaceContext) -> s32 #c_call;

    // Returns the number of vertices on face number iFace
    // iFace is a number in the range {0, 1, ..., getNumFaces()-1}
    m_getNumVerticesOfFace: #type (a0: *SMikkTSpaceContext, a1: s32) -> s32 #c_call;

    // returns the position/normal/texcoord of the referenced face of vertex number iVert.
    // iVert is in the range {0,1,2} for triangles and {0,1,2,3} for quads.
    m_getPosition:          #type (a0: *SMikkTSpaceContext, a1: *float, a2: s32, a3: s32) -> void #c_call;
    m_getNormal:            #type (a0: *SMikkTSpaceContext, a1: *float, a2: s32, a3: s32) -> void #c_call;
    m_getTexCoord:          #type (a0: *SMikkTSpaceContext, a1: *float, a2: s32, a3: s32) -> void #c_call;

    // This function is used to return the tangent and fSign to the application.
    // fvTangent is a unit length vector.
    // For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
    // bitangent = fSign * cross(vN, tangent);
    // Note that the results are returned unindexed. It is possible to generate a new index list
    // But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
    // DO NOT! use an already existing index list.
    m_setTSpaceBasic:       #type (a0: *SMikkTSpaceContext, a1: *float, a2: float, a3: s32, a4: s32) -> void #c_call;

    // This function is used to return tangent space results to the application.
    // fvTangent and fvBiTangent are unit length vectors and fMagS and fMagT are their
    // true magnitudes which can be used for relief mapping effects.
    // fvBiTangent is the "real" bitangent and thus may not be perpendicular to fvTangent.
    // However, both are perpendicular to the vertex normal.
    // For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
    // fSign = bIsOrientationPreserving ? 1.0f : (-1.0f);
    // bitangent = fSign * cross(vN, tangent);
    // Note that the results are returned unindexed. It is possible to generate a new index list
    // But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
    // DO NOT! use an already existing index list.
    m_setTSpace:            #type (a0: *SMikkTSpaceContext, a1: *float, a2: *float, a3: float, a4: float, a5: tbool, a6: s32, a7: s32) -> void #c_call;
}

SMikkTSpaceContext :: struct {
    m_pInterface: *SMikkTSpaceInterface; // initialized with callback functions
    m_pUserData:  *void; // pointer to client side mesh data etc. (passed as the first parameter with every interface call)
}

// these are both thread safe!
genTangSpaceDefault :: (pContext: *SMikkTSpaceContext) -> tbool #foreign mikktspace;
genTangSpace :: (pContext: *SMikkTSpaceContext, fAngularThreshold: float) -> tbool #foreign mikktspace;

#scope_file

mikktspace :: #foreign_library,no_dll "x64/mikktspace";
