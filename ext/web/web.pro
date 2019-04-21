QT          += widgets qml quick concurrent core-private webengine

TEMPLATE    = lib
CONFIG      += staticlib

TARGET = goxui-web

HEADERS += \
        $$PWD/goxui_web.h

SOURCES += \
        $$PWD/goxui_web.cpp

# export static library
header_files.files = $$PWD/goxui_web.h
header_files.path = $$PWD/../../bin
target.path = $$PWD/../../bin
INSTALLS += target header_files
