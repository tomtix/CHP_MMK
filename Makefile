TARGET=projCHP #test_driver
CFLAGS=-std=c++11 -g -Wall -Wextra -fdiagnostics-color=auto -funroll-loops
LDFLAGS= -funroll-loops
LIBS=-lm
GENGETOPT=gengetopt
CC=mpic++

ifdef DEBUG
CFLAGS+=-ggdb -O0 -DDEBUG=1 #-fsanitize=address -fsanitize=undefined
LDFLAGS+=-g #-fsanitize=address -fsanitize=undefined
else
CFLAGS+=-O3 -march=native
endif

ifeq ($(strip $(BLASLIB)),)
LDFLAGS+=-lopenblas
else
LDFLAGS+= -Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_intel_lp64.a \
	${MKLROOT}/lib/intel64/libmkl_core.a ${MKLROOT}/lib/intel64/libmkl_gnu_thread.a \
	-Wl,--end-group ${MKLROOT}/lib/intel64/libmkl_blacs_openmpi_lp64.a \
	-ldl -lpthread -lm -fopenmp
CFLAGS+=-DMKL
endif

OBJ=    obj/cmdline.o \
	obj/main.o \
	obj/perf/perf.o \
	obj/solver.o \
	obj/func.o \
	obj/equation.o \
	obj/proc.o \
	obj/schwarz_printer.o \
	obj/schwarz_solver.o \
	obj/timer.o

obj_test_driver = \
	obj/test_driver.o \
	obj/solver.o \
	obj/equation.o \
	obj/func.o

DEP=$(OBJ:.o=.d)
OBJ_test_driver=$(obj_test_driver:.c=.o)

all: obj obj/perf $(TARGET)

-include $(DEP)

obj:
	mkdir -p obj/

obj/perf:
	mkdir -p obj/perf/

projCHP: $(OBJ)
	$(CC) $^ -o $@ $(LDFLAGS) $(LIBS)

test_driver: $(OBJ_test_driver)
	$(CC) $^ -o $@ $(LDFLAGS) -lgfortran

obj/%.o: src/%.cpp
	@$(CC) -MM -MT $@ $(CFLAGS) $< > obj/$*.d
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	$(RM) $(OBJ_test_driver) $(OBJ) $(DEP) *.d *.o

mrproper: clean
	$(RM) $(TARGET)

genopt: src/projCHP.ggo
	$(GENGETOPT) < $^ --output-dir=src/


