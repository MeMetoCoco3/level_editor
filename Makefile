build:
	@rm -f odin 
	odin build . -out:level_editor
exec: 
	./level_editor
run:
	odin run . -define:title=${TITLE}
	# make run TITLE="something"
debug: 
	odin build . -define:title=${TITLE} -out:debug_le -o:none -debug
	gdb debug_le 
