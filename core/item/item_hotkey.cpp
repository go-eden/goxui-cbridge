//
// Created by sulin on 2018/1/9.
//

#include "item_hotkey.h"

HotKeyItem::HotKeyItem(QObject *parent) : QObject(parent) {
    this->hotkey = nullptr;
}

QString HotKeyItem::getSequence() {
    return this->sequence;
}

void HotKeyItem::setSequence(QString key) {
    // release old hotkey
    this->releaseHotKey();

    // create new hotkey
    qDebug() << "bind hotkey: "<< key;
    QHotkey* hk = new QHotkey(QKeySequence(key), true);
    QObject::connect(hk, &QHotkey::activated, [=]() {
        emit this->activated();
    });
    this->hotkey = hk;
    this->sequence = key;
}

void HotKeyItem::releaseHotKey() {
    if (!this->hotkey) {
        return;
    }
    qDebug() << "release hotkey: "<< this->sequence;
    delete this->hotkey;
    this->hotkey = nullptr;
}

HotKeyItem::~HotKeyItem() {
    this->releaseHotKey();
}
