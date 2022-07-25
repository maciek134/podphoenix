/*
 * Copyright 2015 Podbird Team
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

// Initial Walkthrough tutorial
Walkthrough {
    id: walkthrough
    appName: "Podbird"
    onFinished: {
        console.log("[LOG]: Welcome tour complete")
        settings.firstRun = false
        mainStack.pop()
        mainStack.push(tabs)
    }
    model: [
        Slide1{},
        Slide2{},
        Slide3{},
        Slide4{},
        Slide5{},
        Slide6{},
        Slide7{}
    ]
}
