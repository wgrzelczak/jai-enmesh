#assert(OS == .WINDOWS);

#run {
    set_build_options_dc(.{do_output=false});

    {
        src_files: [..] string;
        array_add(*src_files, "mikktspace.c");
        make_directory_if_it_does_not_exist("x64");
        build_cpp_static_lib("x64/mikktspace", ..src_files, debug=false);
    }

    {
        opts := make_default_generator_options();
        array_add(*opts.libpaths,      "x64");
        array_add(*opts.libnames,      "mikktspace");
        //array_add(*opts.include_paths, ".");
        array_add(*opts.source_files,  "mikktspace.h");
        generate_bindings("mikktspace_bindings.jai", opts);
    }
}

#scope_file

make_default_generator_options :: () -> Generate_Bindings_Options {
    opts: Generate_Bindings_Options;

    array_add(*opts.system_include_paths, GENERATOR_DEFAULT_SYSTEM_INCLUDE_PATH);
    array_add(*opts.extra_clang_arguments, "-x", "c++", "-fms-extensions");

    opts.mimic_spacing_flags &= ~Mimic_Spacing_Flags.VTABLE;
    opts.generate_compile_time_struct_checks = false;

    opts.will_print_bindings = () {
        for context.compiler.global_scope.members {
            visit_declarations(visitor, it);
        }
    };
    return opts;
}

generate_bindings :: (output_filename : string, opts : Generate_Bindings_Options) {
    bindings_builder, success := generate_bindings(opts);
    defer free_buffers(*bindings_builder);
    assert(success);

    show_generator_results();
    success = write_entire_file(output_filename, bindings_builder);
    assert(success, "Could not write generated output to \"%\"\n", output_filename);

    reset_temporary_storage();
}

visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    return .RECURSE;
}


PREFIXES_FOR_TYPES_TO_OMIT :: string.[
];

TYPES_TO_OMIT :: string.[
];


#import "Basic";
#import "Bindings_Generator";
#import "BuildCpp";
#import "Compiler";
#import "File";
#import "String";
#import "System";
#import "Windows_Resources";
