// -*- mode:c++; indent-tabs-mode:nil; -*-

#include <QtGui/QApplication>

#include "qt4app.hh"

int
main(int ac, char** av)
{
  QApplication qapp(ac,av);
  MainWindow mainwindow;
  mainwindow.show();
  return qapp.exec();
}
