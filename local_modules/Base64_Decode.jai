
BASE64_TABLE :: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
#if true {
	BASE64_TABLE_DEC :: u8.[64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64, 64, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64, 64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64];
} else {
	BASE64_TABLE_DEC :: #insert #run make_table();
	make_table :: () -> string {
        tab : [256] u8;
        for 0..255                  tab[it] = 64;
    	for 0..BASE64_TABLE.count-1 tab[BASE64_TABLE[it]] = cast(u8)it;
        
    	fmt : FormatArray;
    	fmt.stop_printing_after_this_many_elements = -1;
    	tmp_context := context;
    	tmp_context.print_style.default_format_array = fmt;
    
    	push_context tmp_context {
        	return sprint("u8.%;", tab);
    	}
    }
}


base64_decode :: (input : [] u8) -> [] u8 #must {
    output_buffer : [] u8;

    {
        count := input.count;
        if count % 4 != 0 {
            count += 4 - (count % 4);
        }
        buffer_size := (count / 4) * 3;
        array_resize(*output_buffer, buffer_size);
    }
    {
        acc          : u32 = 0;
        bits_to_use  : u32 = 0;
        out_iterator : u64 = 0;
        
        for input {
            if BASE64_TABLE_DEC[it] >= 64 break;
            
            acc = (acc << 6) + BASE64_TABLE_DEC[it];
           
            bits_to_use += 6;
            if (bits_to_use >= 8) {
                output_buffer[out_iterator] = cast(u8)((acc >> (bits_to_use - 8)) & 0xFF);
                bits_to_use -= 8;
                out_iterator += 1;
            }
        }
    }
    
    return output_buffer;
}

#scope_file
// We are importing Basic for alloc only. Seems like kind of a waste ... !
#import "Basic";