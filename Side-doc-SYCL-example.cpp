#include <iostream>
#include <sycl.hpp>
#include "mpi.h"

using namespace sycl;

// remove for published version -- only needed to make the mock-up run correctly
#if MPI_VERSION < 4
/* mock up MPI-4.0 features */
#define MPI_PROLOG MPI_Init
#define MPI_EPILOG MPI_Finalize
typedef MPI_Info MPI_Session; const MPI_Session MPI_SESSION_NULL = MPI_INFO_NULL;
int MPI_Session_init(MPI_Info info, MPI_Errhandler errh, MPI_Session* session) { return MPI_Info_dup(info, session); }
int MPI_Session_get_info(MPI_Session session, MPI_Info* info) { return MPI_Info_dup(session, info); }
int MPI_Info_get_string(MPI_Info info, const char* key, int* len, char* val, int* flag) { 
    if (*len <= 0)
        return MPI_Info_get_valuelen(info, key, len, flag);
    else
        return MPI_Info_get(info, key, *len, val, flag); }
int MPI_Group_from_session_pset(MPI_Session session, const char* pset, MPI_Group* group) { return MPI_Comm_group(MPI_COMM_WORLD, group); }
int MPI_Comm_create_from_group(MPI_Group group, const char* tag, MPI_Info info, MPI_Errhandler errh, MPI_Comm* comm) { return MPI_Comm_dup(MPI_COMM_WORLD, comm); }
int MPI_Session_Finalize(MPI_Session* session) { return MPI_Info_free(session); }
#else
int noop_init(int*, char***) { return MPI_SUCCESS; }
int noop_finalize() { return MPI_SUCCESS; }
#define MPI_PROLOG noop_init
#define MPI_EPILOG noop_finlaize
#endif

int main(int argc, char* argv[]) {
    MPI_PROLOG(&argc, &argv); // remove for published version -- only needed to make the mock-up run correctly
    try {
        queue q; // might use a CPU or a GPU or an FPGA, etc

        // information for the user only
        std::cout << "SYCL reports device name: "
            << q.get_device().get_info<info::device::name>() << std::endl;
        std::cout << "SYCL reports device backend: "
            << q.get_backend() << std::endl;

        // query for the type of backend used by the SYCL queue
        const std::string backend_reported_by_sycl = [&q] {
            switch (q.get_backend()) {
            case sycl::_V1::backend::ext_oneapi_level_zero:
                return "level_zero";
                break;
            case sycl::_V1::backend::ext_oneapi_cuda:
                return "cuda";
                break;
            case sycl::_V1::backend::ext_oneapi_hip:
                return "rocm";
                break;
            default:
                return ""; // means fallback to using CPU and "system" memory
                break;
            }
        }();
        std::cout << "SYCL queue backend, translated for MPI: " << backend_reported_by_sycl << std::endl;
        bool queue_uses_gpu_device = backend_reported_by_sycl.length() > 0;
        const std::string requested_mem_kind_for_mpi = queue_uses_gpu_device ? backend_reported_by_sycl + ":device" : "system";
        const std::string info_val_for_mpi_session_init = "system,mpi," + requested_mem_kind_for_mpi;
        std::cout << "Info val string for the request to MPI: " << info_val_for_mpi_session_init << std::endl;
        
        MPI_Session session = MPI_SESSION_NULL;
        MPI_Info info = MPI_INFO_NULL;
        MPI_Group world_group = MPI_GROUP_NULL;
        MPI_Comm comm = MPI_COMM_NULL;
        int my_rank = MPI_PROC_NULL;

        // usage mode: REQUESTED
        MPI_Info_create(&info);
        std::string key_for_mpi("mpi_memory_alloc_kinds");
        MPI_Info_set(info, key_for_mpi.c_str(), info_val_for_mpi_session_init.c_str());
        MPI_Session_init(info, MPI_ERRORS_ARE_FATAL, &session);
        MPI_Info_free(&info);

        // usage mode: PROVIDED
        bool mpi_understands_device_memory = false;
        if (queue_uses_gpu_device) {
            MPI_Session_get_info(session, &info);
            int len = 0, flag = 0;
            MPI_Info_get_string(info, key_for_mpi.c_str(), &len, nullptr, &flag);
            if (flag && len > 0) {
                size_t num_bytes_needed = (1 + (size_t)len) * sizeof(char);
                char* val = static_cast<char*>(malloc(num_bytes_needed));
                if (nullptr == val) std::terminate();
                MPI_Info_get_string(info, key_for_mpi.c_str(), &len, val, &flag);
                std::string val_from_mpi(val);
                std::cout << "looking for substring: " << requested_mem_kind_for_mpi << std::endl;
                std::cout << "within value from MPI: " << val_from_mpi << std::endl;
                if (std::string::npos != val_from_mpi.find(requested_mem_kind_for_mpi)) {
                    mpi_understands_device_memory = true;
                } else {
                    std::cout << "Not found -- this MPI_Session does NOT provide the requested support!" << std::endl;
                }
            } else {
                std::cout << "Info key '" << key_for_mpi << "' not found in MPI_Info from session!" << std::endl;
            }
            MPI_Info_free(&info);
        }
        else {
            // no need to check -- we know that "system" must be provided because it was requested
        }

        // usage mode: ASSERTED
        std::string assert_key_for_mpi("mpi_assert_memory_alloc_kinds");
        if (!queue_uses_gpu_device) {
            std::cout << "SYCL queue is not a GPU -- will fallback to system memory" << std::endl;
            info = MPI_INFO_NULL;
        } else if (mpi_understands_device_memory) {
            std::cout << "MPI says it understands device memory -- will assert during MPI_Comm creation" << std::endl;
            MPI_Info_create(&info);
            MPI_Info_set(info, assert_key_for_mpi.c_str(), requested_mem_kind_for_mpi.c_str());
        } else {
            std::cout << "MPI says it does NOT understand device memory -- will fallback to system memory" << std::endl;
            info = MPI_INFO_NULL;
        }
        std::string pset_for_mpi("mpi:://world");
        MPI_Group_from_session_pset(session, pset_for_mpi.c_str(), &world_group);
        std::string tag_for_mpi("org.mpi-forum.mpi-side-doc.mem-alloc-kinds.sycl-example");
        MPI_Comm_create_from_group(world_group, tag_for_mpi.c_str(), info, MPI_ERRORS_ARE_FATAL, &comm);
        MPI_Group_free(&world_group);
        MPI_Comm_rank(comm, &my_rank);

        // usage mode: ACCEPTED
        bool comm_can_accept_device_memory = false;
        if (queue_uses_gpu_device && mpi_understands_device_memory) {
            MPI_Info_free(&info);
            MPI_Comm_get_info(comm, &info);
            int len = 0, flag = 0;
            MPI_Info_get_string(info, assert_key_for_mpi.c_str(), &len, nullptr, &flag);
            if (flag && len > 0) {
                size_t num_bytes_needed = (1 + (size_t)len) * sizeof(char);
                char* val = static_cast<char*>(malloc(num_bytes_needed));
                if (nullptr == val) std::terminate();
                MPI_Info_get_string(info, assert_key_for_mpi.c_str(), &len, val, &flag);
                std::string val_from_mpi(val);
                std::cout << "looking for substring: " << requested_mem_kind_for_mpi << std::endl;
                std::cout << "within value from MPI: " << val_from_mpi << std::endl;
                if (std::string::npos != val_from_mpi.find(requested_mem_kind_for_mpi)) {
                    comm_can_accept_device_memory = true;
                }
            } else {
                std::cout << "Info key '" << assert_key_for_mpi << "' not found in MPI_Info from comm!" << std::endl;
            }
            MPI_Info_free(&info);
        } else {
            // no need to check -- we did not assert GPU device memory usage and "system" must be accepted
        }

        // allocate a data buffer on GPU or CPU
        int* data_buffer = [&q, &comm_can_accept_device_memory, &my_rank] {
            if (comm_can_accept_device_memory) {
                std::cout << "[rank:" << my_rank << "] MPI says this communicator can accept device memory -- allocating memory on device" << std::endl;
                return malloc_shared<int>(6, q);
            } else {
                std::cout << "[rank:" << my_rank << "] MPI says this communicator CANNOT accept device memory -- allocating memory on system" << std::endl;
                return static_cast<int*>(malloc(6 * sizeof(int)));
            }
        }();

        // define a simple work task for GPU or CPU
        auto do_work = [=]() {
            for (int i = 0; i < 6; ++i)
                data_buffer[i] = (my_rank + 1) * 7;
            };

        // execute the work task using the data buffer on GPU or CPU
        if (comm_can_accept_device_memory) {
            q.submit([&](handler& h) {
                h.single_task(do_work);
            }).wait_and_throw();
            std::cout << "[rank:" << my_rank << "] finished work on GPU" << std::endl;
        }
        else {
            do_work();
            std::cout << "[rank:" << my_rank << "] finished work on CPU" << std::endl;
        }

        MPI_Allreduce(MPI_IN_PLACE, data_buffer, 6, MPI_INT, MPI_MAX, comm);
        std::cout << "[rank:" << my_rank << "] finished reduction" << std::endl;

        MPI_Comm_disconnect(&comm);
        MPI_Session_Finalize(&session);

        std::cout << "[rank:" << my_rank << "] The answer is: " << data_buffer[0] << std::endl;
        if (comm_can_accept_device_memory) {
            free(data_buffer, q);
        }
        else {
            free(data_buffer);
        }
    }
    catch (exception const& e) {
        std::cout << "An exception was caught.\n";
        std::terminate();
    }
    MPI_EPILOG(); // remove for published version -- only needed to make the mock-up run correctly
    return 0;
}