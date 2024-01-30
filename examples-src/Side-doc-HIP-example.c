#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <mpi.h>
#include <hip/hip_runtime_api.h>

#define HIP_CHECK(condition) {                                            \
        hipError_t error = condition;                                     \
        if(error != hipSuccess){                                          \
            fprintf(stderr,"HIP error: %d line: %d\n", error,  __LINE__); \
            MPI_Abort(MPI_COMM_WORLD, error);                             \
        }                                                                 \
    }

#define BUFSIZE 1024

int main(int argc, char *argv[])
{
    int rocm_device_aware = 0;
    int len = 0, flag = 0;
    int *device_buf = NULL;
    MPI_File file;
    MPI_Status status;
    MPI_Info info;

    // usage mode: REQUESTED
    // supply mpi_memory_alloc_kinds to the MPI startup mechansim (not shown)
    MPI_Init(&argc, &argv);
    
    // Usage mode: PROVIDED
    // Query the MPI_INFO object on MPI_COMM_WORLD to
    // determine whether the MPI library provides
    // support for the memory allocation kinds
    // requested via the MPI startup mechanism
    MPI_Comm_get_info(MPI_COMM_WORLD, &info);
    MPI_Info_get_string(info, "mpi_memory_alloc_kinds",
                        &len, NULL, &flag);
    if (flag) {
        char *val, *valptr, *kind;

        val = valptr = (char *) malloc(len);
        if (NULL == val) return 1;

        MPI_Info_get_string(info, "mpi_memory_alloc_kinds",
                            &len, val, &flag);

        while ((kind = strsep(&val, ",")) != NULL) {
            if (strcasecmp(kind, "rocm:device") == 0) {
                rocm_device_aware = 1;
            }
        }
        free(valptr);
    }

    HIP_CHECK(hipMalloc((void**)&device_buf, BUFSIZE * sizeof(int)));

    // The user could optionally create an info object,
    // set mpi_assert_memory_alloc_kind to the memory type
    // it plans to use, and pass this as an argument to
    // MPI_File_open. This approach has the potential to
    // enable further optimizations in the MPI library.
    MPI_File_open(MPI_COMM_WORLD, "inputfile",
		  MPI_MODE_RDONLY, MPI_INFO_NULL, &file);
    
    if (rocm_device_aware) {
        MPI_File_read(file, device_buf, BUFSIZE, MPI_INT, &status);
    }
    else {
        int *tmp_buf;
	tmp_buf = (int*) malloc (BUFSIZE * sizeof(int));
	MPI_File_read(file, tmp_buf, BUFSIZE, MPI_INT, &status);

	HIP_CHECK(hipMemcpyAsync(device_buf, tmp_buf, BUFSIZE * sizeof(int),
		                 hipMemcpyDefault, 0));
	HIP_CHECK(hipStreamSynchronize(0));

	free (tmp_buf);
    }

    // launch compute kernel(s) 
    
    MPI_File_close(&file);
    HIP_CHECK(hipFree(device_buf));

    MPI_Finalize();
    return 0;
}
