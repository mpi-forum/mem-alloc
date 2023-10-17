#include <iostream>
#include <sycl.hpp>
#include "mpi.h"
#include <optional>

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
        return MPI_Info_get(info, key, *len, val, flag);
}
int MPI_Group_from_session_pset(MPI_Session session, const char* pset, MPI_Group* group) { return MPI_Comm_group(MPI_COMM_WORLD, group); }
int MPI_Comm_create_from_group(MPI_Group group, const char* tag, MPI_Info info, MPI_Errhandler errh, MPI_Comm* comm) { return MPI_Comm_dup(MPI_COMM_WORLD, comm); }
int MPI_Session_Finalize(MPI_Session* session) { return MPI_Info_free(session); }
#else
int noop_init(int*, char***) { return MPI_SUCCESS; }
int noop_finalize() { return MPI_SUCCESS; }
#define MPI_PROLOG noop_init
#define MPI_EPILOG noop_finlaize
#endif

enum class InteractionMethod
{
    begin = -1,

    // most preferred
    ComputeUsingQueue_CommunicationUsingDeviceMemory,
    ComputeUsingQueue_CommunicationUsingSharedMemory,
    ComputeUsingQueue_CommunicationUsingHostMemory,

    ComputeWithoutQueue_CommunicationUsingSystemMemory,
    // least preferred

    end
};

int main(int argc, char* argv[]) {
    MPI_PROLOG(&argc, &argv); // remove for published version -- only needed to make the mock-up run correctly
    try {
        sycl::queue q; // might use a CPU or a GPU or an FPGA, etc

        // information for the user only
        std::cout << "SYCL reports device name: "
            << q.get_device().get_info<sycl::info::device::name>() << std::endl;
        std::cout << "SYCL reports device backend: "
            << q.get_backend() << std::endl;

        // query SYCL for the backend and the features it supports
        const auto [qBackendEnum, qSupportsDeviceMem, qSupportsSharedUSM, qSupportsHostUSM] = [&q]() {
            const sycl::device& dev = q.get_device();
            return std::make_tuple(
                q.get_backend(),
                dev.has(sycl::aspect::usm_device_allocations),
                dev.has(sycl::aspect::usm_shared_allocations),
                dev.has(sycl::aspect::usm_host_allocations)
            );
        }();

        // translate the backend reported by the SYCL queue into a "memory allocation kind" string for MPI
        // and the feature support reported by the SYCL queue into "memory allocation restrictor" strings for MPI
        const auto [queue_uses_backend_defined_by_mpi, backend_from_sycl_translated_for_mpi,
            valid_mpi_restrictors_for_backend] = [qBackendEnum] () {
            typedef struct { bool known; std::string kind; struct { std::string device;
                             std::string sharedOrManaged; std::string host; } restrictors; } retType;
            switch (qBackendEnum) {
            case sycl::backend::ext_oneapi_level_zero:
                return retType{ true, "level_zero", {"device", "shared", "host"} };
                break;
            case sycl::backend::ext_oneapi_cuda:
                return retType { true, "cuda", {"device", "managed", "host"} };
                break;
            case sycl::backend::ext_oneapi_hip:
                return retType { true, "rocm", {"device", "managed", "host"} };
                break;
            default:
                // means fallback to using "system" memory kind for MPI
                return retType{ false };
                break;
            }
        }();
        std::cout << "SYCL queue backend ('"<< qBackendEnum <<"'), translated for MPI: " <<
            (queue_uses_backend_defined_by_mpi ? backend_from_sycl_translated_for_mpi
                                               : "NOT DEFINED BY MPI (will tell MPI 'system')") << std::endl;

        MPI_Session session = MPI_SESSION_NULL;
        MPI_Comm comm = MPI_COMM_NULL;
        int my_rank = MPI_PROC_NULL;

        // repeatedly request memory allocation kind:restrictor support in preference order
        // until we find an overlap between what the SYCL backend supports and what MPI provides
        InteractionMethod method;
        for (method = InteractionMethod::begin; method < InteractionMethod::end;
            method = static_cast<InteractionMethod>(((size_t)method) + 1)) {

            // requested_mem_kind_for_mpi regex "system|level_zero:shared|level_zero:device|cuda:managed|cuda:device|rocm:managed|rocm:device"
            const auto requested_mem_kind_for_mpi = [=]() -> std::optional<std::string> {
                switch (method) {
                case InteractionMethod::ComputeUsingQueue_CommunicationUsingDeviceMemory:
                    if (!queue_uses_backend_defined_by_mpi)
                        // method cannot work, MPI does not define this backend
                        return std::nullopt;
                    else if (!qSupportsDeviceMem)
                        // method cannot work, SYCL queue does not support this memory kind
                        return std::nullopt;
                    else
                        return backend_from_sycl_translated_for_mpi + ":" + valid_mpi_restrictors_for_backend.device;
                    break;
                case InteractionMethod::ComputeUsingQueue_CommunicationUsingSharedMemory:
                    if (!queue_uses_backend_defined_by_mpi)
                        // method cannot work, MPI does not define this backend
                        return std::nullopt;
                    else if (!qSupportsSharedUSM)
                        // method cannot work, SYCL queue does not support this memory kind
                        return std::nullopt;
                    else
                        return backend_from_sycl_translated_for_mpi + ":" + valid_mpi_restrictors_for_backend.sharedOrManaged;
                    break;
                case InteractionMethod::ComputeUsingQueue_CommunicationUsingHostMemory:
                    if (!queue_uses_backend_defined_by_mpi)
                        // method cannot work, MPI does not define this backend
                        return std::nullopt;
                    else if (!qSupportsHostUSM)
                        // method cannot work, SYCL queue does not support this memory kind
                        return std::nullopt;
                    else
                        return backend_from_sycl_translated_for_mpi + ":" + valid_mpi_restrictors_for_backend.host;
                    break;
                case InteractionMethod::ComputeWithoutQueue_CommunicationUsingSystemMemory:
                    // this method MUST work, because the "system" memory kind must be provided by MPI when requested
                    return "system";
                    break;

                case InteractionMethod::begin:
                case InteractionMethod::end:
                default:
                    return std::nullopt;
                }
            }();
            if (!requested_mem_kind_for_mpi.has_value())
                continue; // this method cannot work, try the next one

            MPI_Info info = MPI_INFO_NULL;
            std::string key_for_mpi("mpi_memory_alloc_kinds");

            // usage mode: REQUESTED
            MPI_Info_create(&info);
            MPI_Info_set(info, key_for_mpi.c_str(), requested_mem_kind_for_mpi.value().c_str());
            MPI_Session_init(info, MPI_ERRORS_ARE_FATAL, &session);
            MPI_Info_free(&info);
            std::cout << "Created a session, requested memory kind: " << requested_mem_kind_for_mpi.value() << std::endl;

            // usage mode: PROVIDED
            bool provided = false;
            if (requested_mem_kind_for_mpi.value() == "system") {
                // the kind "system" must be provided by MPI when requested
                provided = true; // we have a winner -- exit the for loop
            } else {
                MPI_Session_get_info(session, &info);
                int len = 0, flag = 0;
                MPI_Info_get_string(info, key_for_mpi.c_str(), &len, nullptr, &flag);
                if (flag && len > 0) {
                    size_t num_bytes_needed = (size_t)len * sizeof(char);
                    char* val = static_cast<char*>(malloc(num_bytes_needed));
                    if (nullptr == val) std::terminate();
                    MPI_Info_get_string(info, key_for_mpi.c_str(), &len, val, &flag);
                    std::string val_from_mpi(val);
                    std::cout << "looking for substring: " << requested_mem_kind_for_mpi.value() << std::endl;
                    std::cout << "within value from MPI: " << val_from_mpi << std::endl;
                    if (std::string::npos != val_from_mpi.find(requested_mem_kind_for_mpi.value())) {
                        provided = true; // we have a winner -- assert and exit the for loop
                    } else {
                        std::cout << "Not found -- this MPI_Session does NOT provide the requested support!" << std::endl;
                    }
                    free(val);
                } else {
                    std::cout << "Info key '" << key_for_mpi << "' not found in MPI_Info from session!" << std::endl;
                }
                MPI_Info_free(&info);
            }
            if (!provided)
                MPI_Session_Finalize(&session);
            else {
                // usage mode: ASSERTED
                std::string assert_key_for_mpi("mpi_assert_memory_alloc_kinds");
                std::cout << "MPI says it provides the requested memory kind (" << requested_mem_kind_for_mpi.value() << ")--will assert during MPI_Comm creation" << std::endl;
                MPI_Info_create(&info);
                MPI_Info_set(info, assert_key_for_mpi.c_str(), requested_mem_kind_for_mpi.value().c_str());

                MPI_Group world_group = MPI_GROUP_NULL;
                std::string pset_for_mpi("mpi:://world");
                MPI_Group_from_session_pset(session, pset_for_mpi.c_str(), &world_group);
                std::string tag_for_mpi("org.mpi-forum.mpi-side-doc.mem-alloc-kinds.sycl-example");
                MPI_Comm_create_from_group(world_group, tag_for_mpi.c_str(), info, MPI_ERRORS_ARE_FATAL, &comm);
                MPI_Group_free(&world_group);
                MPI_Comm_rank(comm, &my_rank);

                break;
            }
        } // end of `for (InteractionMethod)`
        if (MPI_SESSION_NULL == session) {
            std::cout << "FAILED to create a usable MPI session" << std::endl; //  (should not happen)
            std::terminate();
        } else
            std::cout << "SUCCESS -- for this session, MPI says the requested memory kind is provided" << std::endl;

        // allocate a data buffer on GPU or CPU
        int* data_buffer = [&q, &method, &my_rank] {
            switch (method) {
            case InteractionMethod::ComputeUsingQueue_CommunicationUsingDeviceMemory:
                std::cout << "[rank:" << my_rank << "] MPI says this communicator can accept device memory -- allocating memory on device" << std::endl;
                return malloc_device<int>(6, q);
                break;
            case InteractionMethod::ComputeUsingQueue_CommunicationUsingSharedMemory:
                std::cout << "[rank:" << my_rank << "] MPI says this communicator can accept shared/managed memory -- allocating USM shared memory " << std::endl;
                return malloc_shared<int>(6, q);
                break;
            case InteractionMethod::ComputeUsingQueue_CommunicationUsingHostMemory:
                std::cout << "[rank:" << my_rank << "] MPI says this communicator can accept host memory -- allocating USM host memory" << std::endl;
                return malloc_host<int>(6, q);
                break;
            case InteractionMethod::ComputeWithoutQueue_CommunicationUsingSystemMemory:
                std::cout << "[rank:" << my_rank << "] MPI says this communicator CANNOT accept device memory -- allocating memory on system" << std::endl;
                return static_cast<int*>(malloc(6 * sizeof(int)));
                break;

            case InteractionMethod::begin:
            case InteractionMethod::end:
            default:
                std::cout << "ERROR: invalid interaction method" << std::endl; //  (should not happen)
                std::terminate();
                break;
            }
        }();

        // define a simple work task for GPU or CPU
        auto do_work = [=]() {
            for (int i = 0; i < 6; ++i)
                data_buffer[i] = (my_rank + 1) * 7;
            };

        // execute the work task using the data buffer on GPU or CPU
        if (method != InteractionMethod::ComputeWithoutQueue_CommunicationUsingSystemMemory) {
            q.submit([&](sycl::handler& h) {
                h.single_task(do_work);
            }).wait_and_throw();
            std::cout << "[rank:" << my_rank << "] finished work on GPU" << std::endl;
        } else {
                do_work();
            std::cout << "[rank:" << my_rank << "] finished work on CPU" << std::endl;
        }

        MPI_Allreduce(MPI_IN_PLACE, data_buffer, 6, MPI_INT, MPI_MAX, comm);
        std::cout << "[rank:" << my_rank << "] finished reduction" << std::endl;

        MPI_Comm_disconnect(&comm);
        MPI_Session_Finalize(&session);

        int answer = INT_MAX;
        if (method == InteractionMethod::ComputeUsingQueue_CommunicationUsingDeviceMemory) {
            q.memcpy(&answer, &data_buffer[0], sizeof(int)).wait_and_throw();
        } else {
            answer = data_buffer[0];
        }
        std::cout << "[rank:" << my_rank << "] The answer is: " << answer << std::endl;
        if (method != InteractionMethod::ComputeWithoutQueue_CommunicationUsingSystemMemory) {
            free(data_buffer, q);
        } else {
            free(data_buffer);
        }
    }
    catch (sycl::exception const& e) {
        std::cout << "An exception was caught.\n";
        std::terminate();
    }
    MPI_EPILOG(); // remove for published version -- only needed to make the mock-up run correctly
    return 0;
}
