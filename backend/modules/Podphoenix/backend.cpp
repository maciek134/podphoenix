/*
 * Copyright 2015 Michael Sheldon <mike@mikeasoft.com>
 *
 * This file is part of Podphoenix.
 *
 * Podphoenix is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Podphoenix is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QtQml>
#include <QtQml/QQmlContext>
#include <QDebug>

#include "backend.h"
#include "filemanager.h"

void BackendPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("Podphoenix"));

    qmlRegisterType<FileManager>(uri, 1, 0, "FileManager");
}

void BackendPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}
