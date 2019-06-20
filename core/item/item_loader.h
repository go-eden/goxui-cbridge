#ifndef ITEM_LOADER_H
#define ITEM_LOADER_H

#include <QObject>
#include <QQmlApplicationEngine>
#include <private/qquickloader_p.h>

class LoaderItem : public QQuickLoader {
    Q_OBJECT

public:
    static QQmlApplicationEngine* engine;

public:
    explicit LoaderItem(QQuickItem *parent = nullptr);

    void setSource(const QUrl &);

//    Q_INVOKABLE void setSource(QQmlV4Function *v);

};

#endif // ITEM_LOADER_H
