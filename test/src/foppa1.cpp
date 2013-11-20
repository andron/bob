// -*- mode:c++; indent-tabs-mode:nil; -*-

#include "foppa/foppa.hh"

#include <iostream>

extern int global_integer;

Foppa::Foppa(int ac, char** av)
{
  for (int i=0; i<ac; ++i)
  {
    std::cout << __func__ << ": " << i << " " << av[i] << std::endl;
    if (i > 100)
      break;
  }
}

Foppa::~Foppa()
{
  std::cout << __func__ << ": Done " << global_integer << std::endl;
}
