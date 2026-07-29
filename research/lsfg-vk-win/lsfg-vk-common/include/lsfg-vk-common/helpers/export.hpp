/* SPDX-License-Identifier: GPL-3.0-or-later */

#pragma once

#if defined(_WIN32)
#define LSFGVK_PUBLIC
#define LSFGVK_LAYER_EXPORT extern "C" __declspec(dllexport)
#else
#define LSFGVK_PUBLIC [[gnu::visibility("default")]]
#define LSFGVK_LAYER_EXPORT extern "C" __attribute__((visibility("default")))
#endif
