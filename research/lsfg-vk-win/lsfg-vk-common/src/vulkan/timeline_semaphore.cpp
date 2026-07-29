/* SPDX-License-Identifier: GPL-3.0-or-later */

#include "lsfg-vk-common/vulkan/timeline_semaphore.hpp"
#include "lsfg-vk-common/vulkan/external_handle.hpp"
#include "lsfg-vk-common/helpers/errors.hpp"
#include "lsfg-vk-common/helpers/pointers.hpp"
#include "lsfg-vk-common/vulkan/vulkan.hpp"

#include <cstdint>
#include <optional>

#include <vulkan/vulkan_core.h>

using namespace vk;

namespace {
    /// create a timeline semaphore
    ls::owned_ptr<VkSemaphore> createTimelineSemaphore(const vk::Vulkan& vk, uint32_t initial,
            std::optional<ExternalHandle> importHandle,
            std::optional<ExternalHandle*> exportHandle) {
        VkSemaphore handle{};

        const VkExportSemaphoreCreateInfo exportInfo{
            .sType = VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO,
#if defined(_WIN32)
            .handleTypes = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT
#else
            .handleTypes = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT
#endif
        };
        const VkSemaphoreTypeCreateInfo typeInfo{
            .sType = VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO,
            .pNext = (importHandle.has_value() || exportHandle.has_value()) ? &exportInfo : nullptr,
            .semaphoreType = VK_SEMAPHORE_TYPE_TIMELINE,
            .initialValue = initial
        };
        const VkSemaphoreCreateInfo semaphoreInfo{
            .sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
            .pNext = &typeInfo,
        };
        auto res = vk.df().CreateSemaphore(vk.dev(), &semaphoreInfo, VK_NULL_HANDLE, &handle);
        if (res != VK_SUCCESS)
            throw ls::vulkan_error(res, "vkCreateSemaphore() failed");

        if (importHandle.has_value()) {
#if defined(_WIN32)
            const VkImportSemaphoreWin32HandleInfoKHR importInfo{
                .sType = VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR,
                .semaphore = handle,
                .handleType = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT,
                .handle = *importHandle
            };
            res = vk.df().ImportSemaphoreWin32HandleKHR(vk.dev(), &importInfo);
            if (res == VK_SUCCESS)
                CloseHandle(*importHandle);
#else
            // import semaphore from fd
            const VkImportSemaphoreFdInfoKHR importInfo{
                .sType = VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR,
                .semaphore = handle,
                .handleType = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT,
                .fd = *importHandle // closes the fd
            };
            res = vk.df().ImportSemaphoreFdKHR(vk.dev(), &importInfo);
#endif
            if (res != VK_SUCCESS)
                throw ls::vulkan_error(res, "vkImportSemaphoreExternalHandle() failed");
        }

        if (exportHandle.has_value()) {
#if defined(_WIN32)
            const VkSemaphoreGetWin32HandleInfoKHR getHandleInfo{
                .sType = VK_STRUCTURE_TYPE_SEMAPHORE_GET_WIN32_HANDLE_INFO_KHR,
                .semaphore = handle,
                .handleType = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT
            };
            ExternalHandle externalHandle{};
            res = vk.df().GetSemaphoreWin32HandleKHR(vk.dev(), &getHandleInfo, &externalHandle);
            if (res != VK_SUCCESS)
                throw ls::vulkan_error(res, "vkGetSemaphoreWin32HandleKHR() failed");
#else
            // export semaphore to fd
            const VkSemaphoreGetFdInfoKHR getFdInfo{
                .sType = VK_STRUCTURE_TYPE_SEMAPHORE_GET_FD_INFO_KHR,
                .semaphore = handle,
                .handleType = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT
            };
            ExternalHandle externalHandle{};
            res = vk.df().GetSemaphoreFdKHR(vk.dev(), &getFdInfo, &externalHandle);
            if (res != VK_SUCCESS)
                throw ls::vulkan_error(res, "vkGetSemaphoreFdKHR() failed");
#endif
            **exportHandle = externalHandle;
        }

        return ls::owned_ptr<VkSemaphore>(
            new VkSemaphore(handle),
            [dev = vk.dev(), defunc = vk.df().DestroySemaphore](VkSemaphore& semaphore) {
                defunc(dev, semaphore, VK_NULL_HANDLE);
            }
        );
    }
}

TimelineSemaphore::TimelineSemaphore(const vk::Vulkan& vk, uint32_t initial,
        std::optional<ExternalHandle> importHandle,
        std::optional<ExternalHandle*> exportHandle)
    : semaphore(createTimelineSemaphore(vk, initial, importHandle, exportHandle)) {}

void TimelineSemaphore::signal(const vk::Vulkan& vk, uint64_t value) const {
    const VkSemaphoreSignalInfo signalInfo{
        .sType = VK_STRUCTURE_TYPE_SEMAPHORE_SIGNAL_INFO,
        .semaphore = *this->semaphore,
        .value = value
    };
    auto res = vk.df().SignalSemaphoreKHR(vk.dev(), &signalInfo);
    if (res != VK_SUCCESS)
        throw ls::vulkan_error(res, "vkSignalSemaphore() failed");
}

bool TimelineSemaphore::wait(const vk::Vulkan& vk, uint64_t value, uint64_t timeout) const {
    const VkSemaphoreWaitInfo waitInfo{
        .sType = VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO,
        .semaphoreCount = 1,
        .pSemaphores = &*this->semaphore,
        .pValues = &value
    };
    auto res = vk.df().WaitSemaphoresKHR(vk.dev(), &waitInfo, timeout);
    if (res != VK_SUCCESS && res != VK_TIMEOUT)
        throw ls::vulkan_error(res, "vkWaitSemaphores() failed");

    return res == VK_SUCCESS;
}
