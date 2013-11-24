// -*- mode:c++; indent-tabs-mode:nil; -*-

#include <QtGui/QApplication>

#include "qt4app.hh"

#include "qt4app_extra.hh"

int
main(int ac, char** av)
{
  QApplication qapp(ac,av);
  MainWindow mainwindow;
  mainwindow.show();

  Foppa f;
  Sudden s;
  Zlutten z;

  return qapp.exec();
}
