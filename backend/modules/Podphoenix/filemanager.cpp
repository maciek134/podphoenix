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

#include <QFile>
#include <QDebug>
#include <QDir>
#include <QUrl>
#include <QStandardPaths>

#include "filemanager.h"

FileManager::FileManager(QObject *parent):
    QObject(parent),
    m_podcastDir(QStandardPaths::writableLocation(QStandardPaths::DataLocation) + QDir::separator() + "podcasts")
{

}

FileManager::~FileManager() {

}

QString FileManager::podcastDirectory() const
{
    return m_podcastDir;
}

void FileManager::deleteFile(QString path) {
    QFile file(path);
    if (file.exists()) {
        file.remove();
    }
}

QString FileManager::saveDownload(QString origPath) {
    QDir destDir(m_podcastDir);
    if(!destDir.exists()) {
        destDir.mkpath(m_podcastDir);
    }
    QFileInfo fi(origPath);
    QFile *destFile;
    QString filePath;
    int attempts = 0;
    do {
        filePath = m_podcastDir + QDir::separator() + QUrl::fromPercentEncoding(fi.fileName().toUtf8());
        if (attempts > 0) {
            filePath += "." + QString::number(attempts);
        }
        destFile = new QFile(filePath);
        attempts++;
    } while (destFile->exists());
    QFile::rename(origPath, filePath);
    return filePath;
}

QStringList FileManager::getDownloadedEpisodes() {
    QDir destDir(m_podcastDir);
    QStringList filters;
    filters << "*.mp3" << "*.mp3.*" << "*.m4a" << "*.m4a.*" << "*.ogg" << "*.ogg.*" << "*.oga" << "*.oga.*" << "*.wma";
    destDir.setNameFilters(filters);
    return destDir.entryList();
}
