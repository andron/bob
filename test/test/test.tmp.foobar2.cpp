// -*- mode:c++; indent-tabs-mode:nil; -*-

#include <iostream>
#include <cstdlib>
#include <string>

int
main(int ac, char**)
{
  std::string tstdir = getenv("_TSTDIR");
  std::cout << "\targs:   " << ac << std::endl
            << "\ttstdir: " << tstdir << std::endl;
  return 0;
}
