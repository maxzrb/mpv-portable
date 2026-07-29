set(COMMON_SOURCES
    "src/configuration/config.cpp"
    "src/configuration/detection.cpp"
    "src/helpers/errors.cpp"
    "src/helpers/paths.cpp"
    "src/vulkan/buffer.cpp"
    "src/vulkan/command_buffer.cpp"
    "src/vulkan/descriptor_pool.cpp"
    "src/vulkan/descriptor_set.cpp"
    "src/vulkan/fence.cpp"
    "src/vulkan/image.cpp"
    "src/vulkan/sampler.cpp"
    "src/vulkan/semaphore.cpp"
    "src/vulkan/shader.cpp"
    "src/vulkan/timeline_semaphore.cpp"
    "src/vulkan/vulkan.cpp")

add_library(lsfg-vk-common STATIC ${COMMON_SOURCES})

target_include_directories(lsfg-vk-common
    PUBLIC include)

target_include_directories(lsfg-vk-common SYSTEM
    PUBLIC thirdparty/include)

if(WIN32)
    target_compile_definitions(lsfg-vk-common PUBLIC
        VK_USE_PLATFORM_WIN32_KHR
        WIN32_LEAN_AND_MEAN
        NOMINMAX)
endif()

if(LSFGVK_INSTALL_DEVELOP)
    install(TARGETS lsfg-vk-common
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}")
    install(DIRECTORY "include/lsfg-vk-common/"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/lsfg-vk-common"
        FILES_MATCHING PATTERN "*.hpp")
endif()
