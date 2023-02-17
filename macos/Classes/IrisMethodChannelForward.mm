// Relative import to be able to reuse the C sources.
// See the comment in ../{projectName}}.podspec for more information.

// Ignore warning of [-Wdocumentation] of dart_api_dl.h
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "../../src/iris_event.cc"
#pragma clang diagnostic pop

#include "../../src/iris_life_cycle_observer.mm"
