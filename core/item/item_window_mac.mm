//
// Created by sulin on 2017/9/29.
//

#include <Cocoa/Cocoa.h>
#include <QtConcurrent>
#include "item_window.h"

// adjust title
void adjustTitle(WindowItem *w, WindowTitleItem *titleItem) {
    NSView *view = reinterpret_cast<NSView *>(w->winId());
    if (view == nullptr || view.window == nullptr || titleItem == nullptr) {
        return;
    }
    NSWindow *win = view.window;
    static NSWindowButton arr[]{NSWindowCloseButton, NSWindowMiniaturizeButton, NSWindowZoomButton};
    for (int i=0, idx=0; i<4; i++) {
        NSButton *btn = [win standardWindowButton:arr[i]];
        if (btn == nullptr) {
            continue;
        }
        NSRect frame = btn.frame;
        frame.origin.y = titleItem->height() / 2 - NSHeight(frame) / 2;
        frame.origin.x = frame.origin.y + idx * (NSWidth(frame) + 6);
        [btn setFrame:frame];
        idx ++;
    }
}

// initilize titlebar, mount itself onto window
WindowTitleItem::WindowTitleItem(QQuickItem *parent) : QQuickItem(parent) {
    this->setAcceptedMouseButtons(Qt::LeftButton);
    QObject::connect(this, &QQuickItem::windowChanged, [=](QQuickWindow *w) {
        if (WindowItem* window = dynamic_cast<WindowItem*>(w)) {
            window->setTitleBar(this);
        }
    });
}

// release
WindowTitleItem::~WindowTitleItem() {
    if (this->window() == nullptr) {
        return;
    }
    if (WindowItem* window = dynamic_cast<WindowItem*>(this->window())) {
        window->setTitleBar(nullptr);
    }
}

// implement resize on double click
void WindowTitleItem::mouseDoubleClickEvent(QMouseEvent *){
    QWindow *win = this->window();
    if (win == nullptr) {
        return;
    }
    if (win->visibility() == QWindow::Maximized) {
        win->showNormal();
    } else if (win->visibility() != QWindow::FullScreen) {
        win->showMaximized();
    }
}

// response mousepress, begin drag operation.
void WindowTitleItem::mousePressEvent(QMouseEvent *event){
    if (WindowItem* window = dynamic_cast<WindowItem*>(this->window())) {
        window->startDrag();
    } else {
        QQuickItem::mousePressEvent(event); // block children item
    }
}

// initilize window, and register MouseDown event
WindowItem::WindowItem(QWindow *parent) : QQuickWindow(parent) {
    this->oldRatio = 0;
    this->title = nullptr;
    this->macLastEvent = nullptr;
    this->macEventMonitor = nullptr;
    // init window, this isn't enough
    NSView *view = reinterpret_cast<NSView *>(this->winId());
    NSWindow *window = view.window;
    window.styleMask |= NSFullSizeContentViewWindowMask | NSTitledWindowMask;
    window.titleVisibility = NSWindowTitleHidden;
    window.titlebarAppearsTransparent = true;
    // listen mouse drag event and route to NSWindow
    this->macEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *e) {
        this->macLastEvent = e;
        return e;
    }];
    adjustTitle(this, title);
}

// clear event handler
WindowItem::~WindowItem() {
    if (this->macEventMonitor != nullptr) {
        id tmp = reinterpret_cast<id>(this->macEventMonitor);
        [NSEvent removeMonitor:tmp];
    }
}

// handle drag
void WindowItem::startDrag() {
    NSView *view = reinterpret_cast<NSView *>(this->winId());
    if (!this->macLastEvent || !view || !view.window) {
        return;
    }
    NSEvent *e = reinterpret_cast<NSEvent *>(this->macLastEvent); // will it be released earily?
    [view.window performWindowDragWithEvent:e];
}

// setup customize titlebar
void WindowItem::setTitleBar(WindowTitleItem *item) {
    NSView *mainView = reinterpret_cast<NSView *>(this->winId());
    if (mainView == nullptr || mainView.window == nullptr) {
        return;
    }
    if (!this->flags().testFlag(Qt::FramelessWindowHint)) {
        if (this->title) {
            [mainView.window removeTitlebarAccessoryViewControllerAtIndex:0]; // remove old titlebar
        }
        this->title = item;
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, item->height() - 22)]; // default height=22
        NSTitlebarAccessoryViewController* titleCtl = [NSTitlebarAccessoryViewController new];
        titleCtl.view = view;
        titleCtl.fullScreenMinHeight = 0;
        [mainView.window addTitlebarAccessoryViewController:titleCtl];
        adjustTitle(this, title);
    }
}

// Handle All event
bool WindowItem::event(QEvent *event) {
    // release old MouseDown event
    if (event->type() == QEvent::MouseButtonRelease || event->type() == QEvent::FocusOut) {
        this->macLastEvent = nullptr;
    }
    NSView *view = reinterpret_cast<NSView*>(this->winId());
    // support custom title
    if (!this->flags().testFlag(Qt::FramelessWindowHint)) {
        if (event->type() == QEvent::Resize) {
            adjustTitle(this, title);
        }
        if (event->type() == QEvent::WindowStateChange) {
            NSWindow *window = view.window;
            window.styleMask |= NSFullSizeContentViewWindowMask | NSTitledWindowMask;
            window.titleVisibility = NSWindowTitleHidden;
            window.titlebarAppearsTransparent = true;
            adjustTitle(this, title);
        }
    }
    // Fix ratio bug for 5.9...
    if (QT_VERSION_MINOR < 12) {
        qreal newRatio = this->devicePixelRatio();
        if (view != nullptr && view.layer != nil && int(oldRatio) != int(newRatio)) {
            [view.layer setContentsScale: newRatio]; // Force flush ratio
            QRegion region(0, 0, width(), height());
            QWindow::exposeEvent(new QExposeEvent(region));
            oldRatio = newRatio;
        }
    }
    // support fakeClose
    if (event->type() == QEvent::Close && this->fakeClose) {
        this->hide();
        return true;
    }
    return QQuickWindow::event(event);
}

// Do nothing for darwin
bool WindowItem::nativeEvent(const QByteArray &eventType, void *message, long *result) {
    return QQuickWindow::nativeEvent(eventType, message, result);
}
