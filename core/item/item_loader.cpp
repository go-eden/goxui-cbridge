#include "item/item_loader.h"

QQmlApplicationEngine *LoaderItem::engine = nullptr;

LoaderItem::LoaderItem(QQuickItem *parent) : QQuickLoader (parent) {

}

void LoaderItem::setSource(const QUrl &src) {
    QQuickLoader::setSource (QUrl(""));
    if (LoaderItem::engine) {
        LoaderItem::engine->trimComponentCache();
    }
    QQuickLoader::setSource (src);
}

//void LoaderItem::setSource(QQmlV4Function *v) {
//    QQuickLoader::setSource (QUrl(""));
//    if (LoaderItem::engine) {
//        LoaderItem::engine->trimComponentCache();
//    }
//    QQuickLoader::setSource (v);
//}
