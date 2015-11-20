/*
 * This is a small program to verify the linking of multiple files
 * on the 219x. It doesn't do anything useful.
 */
	.pagewidth 40;
	.leftmargin 10;

	.global link2a;
	.global link2b, link2c, link2d;
	.global link2e, link2f, link2g;
	.extern link1a, link1b, link1c, link1d;
	.extern link1e, link1f, link1g;
	.section/PM program0;
link2a:
	do link2g until forever;
link2b:	
	if eq jump link1a;
link2c:
	jump link1b;
link2d:
	call link1c;
link2e:
	ljump link1d;
link2f:
	lcall link1e;
link2g:
	nop; 
