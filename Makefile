build:
	@rm -f odin 
	odin build . -out:level_editor
exec: 
	./level_editor
run:
	odin run .
run_c: 
	odin run . -define:DEBUG_COLISION=true
debug: 
	odin build . -out:debug_le -o:none -debug
	gdb debug_le 
