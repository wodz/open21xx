/*
 * This is a small program to verify the linking of multiple files
 * on the 219x. It doesn't do anything useful.
 */
	.pagewidth 40;
	.leftmargin 10;

	.global link1a;
	.global link1b, link1c, link1d;
	.global link1e, link1f, link1g;
	.extern link2a, link2b, link2c, link2d;
	.extern link2e, link2f, link2g;
	.section/PM program0;
link1a:
	do link2g until forever;
link1b:	
	if eq jump link2a;
link1c:
	jump link2b;
link1d:
	call link2c;
link1e:
	ljump link2d;
link1f:
	lcall link2e;
link1g:
	nop; 

