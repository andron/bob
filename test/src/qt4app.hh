// -*- mode:c++; indent-tabs-mode:nil; -*-

#ifndef __qt4app_hh__
#define __qt4app_hh__

#include <QtGui/QMainWindow>

#include "ui_qt4app.h"
#include "ui_qt4widget1.h"
#include "ui_qt4widget2.h"
#include "ui_qt4widget3.h"
#include "ui_qt4widget4.h"
#include "ui_qt4widget5.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
  Q_OBJECT

 public:
  MainWindow(QWidget* parent = nullptr)
      : QMainWindow(parent),
        _ui(new Ui::MainWindow)
  {
    _ui->setupUi(this);
  }

  ~MainWindow()
  {
    delete _ui;
  }

 private:
  Ui::MainWindow* _ui;
};

#endif // __qt4app_hh__
