/*
OUTPUT_FORMAT("binary");
*/

ENTRY(main);

SECTIONS {
		. = 0x0;
        .text        : {*(.text)}
        .data        : {*(.data)}
}

