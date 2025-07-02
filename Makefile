build:
	@rm -f odin 
	odin build . -out:level_editor
exec: 
	./level_editor
run:
	odin run . -define:title=${TITLE}
	# make run TITLE="something"
run_c: 
	odin run . -define:DEBUG_COLISION=true
debug: 
	odin build . -out:debug_le -o:none -debug
	gdb debug_le 
