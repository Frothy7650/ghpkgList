run:
	v run main.v
linux:
	v -os linux main.v -o main.bin
windows:
	v -os windows main.v -o main.exe
clean:
	rm *.bin *.exe