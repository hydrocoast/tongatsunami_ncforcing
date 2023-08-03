
FC = $(shell nf-config --fc) 
FFLAGS = $(shell nf-config --fflags)
FLIBS = $(shell nf-config --flibs)
EXE = xread_msmnc
FILE = test_read.f90

.PHONY: exe clean

exe:
	$(FC) $(FILE) $(FFLAGS) $(FLIBS) -o $(EXE)

clean:
	-rm -f $(EXE)