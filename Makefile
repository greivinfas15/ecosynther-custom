#matrixGPU: kernel.o main.o hostOnly.o
#	nvcc -lcublas main.o kernel.o hostOnly.o -o matrixGPU 

#main.o: main.cu
#	nvcc  -lcublas main.cu -c -o main.o

TARGET = libmatrixgpu.a
OBJS = hostOnly.o

$(TARGET): $(OBJS)
	ar r libmatrixgpu.a $(OBJS)
	cp $(TARGET) ..	

hostOnly.o : hostOnly.cu
	nvcc -c hostOnly.cu -o hostOnly.o -lcuda -lcudart -arch=sm_20

clean:
	rm *.a *.o
