/* SPDX-License-Identifier: GPL-3.0-or-later */

#pragma once

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace vk {
#if defined(_WIN32)
    using ExternalHandle = HANDLE;
#else
    using ExternalHandle = int;
#endif
}
