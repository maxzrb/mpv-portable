/* SPDX-License-Identifier: GPL-3.0-or-later */

#include "lsfg-vk-common/vulkan/semaphore.hpp"
#include "lsfg-vk-common/vulkan/external_handle.hpp"
#include "lsfg-vk-common/helpers/errors.hpp"
#include "lsfg-vk-common/helpers/pointers.hpp"
#include "lsfg-vk-common/vulkan/vulkan.hpp"

#include <optional>

#include <vulkan/vulkan_core.h>

using namespace vk;

namespace {
    /// create a semaphore
    ls::owned_ptr<VkSemaphore> createSemaphore(const vk::Vulkan& vk,
            std::optional<ExternalHandle> externalHandle) {
        VkSemaphore handle{};

        const VkExportSemaphoreCreateInfo exportInfo{
            .sType = VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO,
#if defined(_WIN32)
            .handleTypes = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT
#else
            .handleTypes = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT
#endif
        };
        const VkSemaphoreCreateInfo semaphoreInfo{
            .sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
            .pNext = externalHandle.has_value() ? &exportInfo : nullptr
        };
        auto res = vk.df().CreateSemaphore(vk.dev(), &semaphoreInfo, VK_NULL_HANDLE, &handle);
        if (res != VK_SUCCESS)
            throw ls::vulkan_error(res, "vkCreateSemaphore() failed");

        if (externalHandle.has_value()) {
#if defined(_WIN32)
            const VkImportSemaphoreWin32HandleInfoKHR importInfo{
                .sType = VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR,
                .semaphore = handle,
                .handleType = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT,
                .handle = *externalHandle
            };
            res = vk.df().ImportSemaphoreWin32HandleKHR(vk.dev(), &importInfo);
            if (res == VK_SUCCESS)
                CloseHandle(*externalHandle);
#else
            // import semaphore from fd
            const VkImportSemaphoreFdInfoKHR importInfo{
                .sType = VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR,
                .semaphore = handle,
                .handleType = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT,
                .fd = *externalHandle // closes the fd
            };
            res = vk.df().ImportSemaphoreFdKHR(vk.dev(), &importInfo);
#endif
            if (res != VK_SUCCESS)
                throw ls::vulkan_error(res, "vkImportSemaphoreExternalHandle() failed");
        }

        return ls::owned_ptr<VkSemaphore>(
            new VkSemaphore(handle),
            [dev = vk.dev(), defunc = vk.df().DestroySemaphore](VkSemaphore& semaphore) {
                defunc(dev, semaphore, VK_NULL_HANDLE);
            }
        );
    }
}

Semaphore::Semaphore(const vk::Vulkan& vk, std::optional<ExternalHandle> externalHandle)
    : semaphore(createSemaphore(vk, externalHandle)) {}
