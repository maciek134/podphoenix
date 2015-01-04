/*
 * Copyright 2015 Michael Sheldon <mike@mikeasoft.com>
 *
 * This file is part of Podbird.
 *
 * Podbird is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Podbird is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QFile>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>

#include "filemanager.h"

FileManager::FileManager(QObject *parent):
    QObject(parent)
{

}

FileManager::~FileManager() {

}

void FileManager::deleteFile(QString path) {
    QFile file(path);
    if (file.exists()) {
        file.remove();
    }
}

QString FileManager::saveDownload(QString origPath) {
    QString destination = QStandardPaths::writableLocation(QStandardPaths::DataLocation) + QDir::separator() + "podcasts";
    QDir destDir(destination);
    if(!destDir.exists()) {
        destDir.mkpath(destination);
    }
    QFileInfo fi(origPath);
    QFile *destFile;
    QString filePath;
    int attempts = 0;
    do {
        filePath = destination + QDir::separator() + fi.fileName();
        if (attempts > 0) {
            filePath += "." + QString::number(attempts);
        }
        destFile = new QFile(filePath);
        attempts++;
    } while (destFile->exists());
    QFile::rename(origPath, filePath);
    return filePath;
}
