#pragma once
#if defined(__has_include)
# if __has_include("buildinfo.h")
#  include "buildinfo.h"
# endif
#endif

#ifndef PRODUCT
# define PRODUCT "SOVRN"
#endif
#ifndef VERSION
# define VERSION "0.0.0"
#endif
#ifndef COMMIT
# define COMMIT "unknown"
#endif
#ifndef BUILD_EPOCH
# define BUILD_EPOCH "0"
#endif
#ifndef TRIPLE
# define TRIPLE "x86_64-efi"
#endif
#ifndef TOOLCHAIN
# define TOOLCHAIN "clang"
#endif
