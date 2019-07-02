all:
	@clang -framework Cocoa -framework OpenGL -framework CoreVideo -framework AudioUnit -framework IOKit -lglfw3 main.c -o main
	@./main
	@rm ./main
