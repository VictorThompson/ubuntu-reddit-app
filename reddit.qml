import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import QtWebKit 3.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import "storage.js" as Storage
import "javascript.js" as Js

/*!
    \brief MainView with Tabs element.
           First Tab has a single Label and
           second Tab has a single ToolbarAction.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "reddit"
    width: units.gu(45)
    height: units.gu(80)

    Tabs {
        id: tabs
        anchors.fill: parent
        selectedTabIndex: 0

        // First tab begins here
        Tab {
            id: subreddittab
            anchors.fill: parent
            property string url: "/"
            Component.onCompleted: {
                if (Storage.getSetting("autologin") == "true") {
                    login()
                }
            }

            Item {
                id: dialog

                anchors.fill: parent
                z: 1000

                // We want to be a child of the root item so that we can cover
                // the whole scene with our "dim" overlay.
                parent: subreddittab

                default property alias __children: dynamicColumn.children

                function showSubredditPrompt () {
                    userloggedin.visible = false
                    gotosub.visible = true
                    dialogWindow.visible = true
                    dimBackground.visible = true
                    mouseBlocker.visible = true
                }
                function showLoginPrompt () {
                    userloggedin.visible = true
                    gotosub.visible = false
                    dialogWindow.visible = true
                    dimBackground.visible = true
                    mouseBlocker.visible = true
                }
                function hidePrompt () {
                    userloggedin.visible = false
                    gotosub.visible = false
                    dialogWindow.visible = false
                    dimBackground.visible = false
                    mouseBlocker.visible = false
                }

                MouseArea {
                    id: mouseBlocker
                    anchors.fill: parent
                    onPressed: mouse.accepted = true
                    visible: false

                    // FIXME: This does not block touch events :(
                }

                Rectangle {
                    id: dimBackground
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.4
                    visible: false

                }

                Rectangle {
                    id: dialogWindow

                    color: "#efefef"

                    width: 300
                    height: 150
                    visible: false


                    border {
                        width: 1
                        color: "#bfbfbf"
                    }

                    smooth: true
                    radius: 5

                    anchors.centerIn: parent

                    Item {
                        id: staticContent
                        anchors.centerIn: parent
                        anchors.fill: parent
                        anchors.margins: 10

                        Rectangle {
                            id: userloggedin
                            anchors.centerIn: parent
                            anchors.fill: parent

                            Text {
                                id: loggedin

                                width: parent.width
                                height: units.gu(8)

                                text: "could not login, check settings"
                                wrapMode: Text.Wrap
                                opacity: .6

                                enabled: parent.visible

                                font.pixelSize: 20
                            }

                            Button {
                                id: loginokbutton
                                text: "ok"
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                height: units.gu(4)
                                width: parent.width / 2
                                onClicked: {
                                    dialog.hidePrompt()
                                }
                            }
                        }

                        Rectangle {
                            id: gotosub
                            anchors.centerIn: parent
                            anchors.fill: parent

                            TextField {
                                id: subreddittextfield

                                width: parent.width
                                height: units.gu(8)

                                enabled: parent.visible

                                font.pixelSize: 20
                            }
                            Text {
                                id: subreddittext

                                width: parent.width
                                height: units.gu(4)

                                anchors.top: subreddittextfield.bottom
                                anchors.topMargin: 10
                                enabled: parent.visible
                                text: "which subreddit?"
                                opacity: .6

                                font.pixelSize: 14
                            }

                            Button {
                                id: promptokbutton
                                text: "ok"
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                height: units.gu(4)
                                width: parent.width / 2
                                onClicked: {
                                    subreddittab.url = "/"
                                    if (subreddittextfield.text !== "") {
                                        var split = subreddittextfield.text.split("/")
                                        var i = 0
                                        for (; split.length; i++) {
                                            if ( split[i] !== "" && split[i] !== null && split[i] !== "r") break
                                        }
                                        if (split[i] !== null && split.length > i && split[i].length > 0) {
                                            subreddittab.url = "/r/" + split[i]
                                        }
                                    }
                                    reloadTabs()
                                    dialog.hidePrompt()
                                }
                            }

                            Button {
                                id: promptcancelbutton
                                text: "cancel"
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                height: units.gu(4)
                                width: parent.width / 2
                                onClicked: {
                                    dialog.hidePrompt()
                                }
                            }
                        }

                        Column {
                            id: dynamicColumn
                            spacing: 5
                            anchors {
                                margins: 10
                                bottom: staticContent.bottom
                                horizontalCenter: staticContent.horizontalCenter
                            }
                        }
                    }
                }
            }

            page: Page {
                id: subredditpage
                anchors.margins: units.gu(4)
                Component.onCompleted: {
                    if (Storage.getSetting("initialized") !== "true") {
                        // initialize settings
                        console.debug("settings not initialized on subreddit load")
                    }
                }

                tools: ToolbarActions {
                    id: toolbar
                    active: true
                    function chooseIcon (text) {
                        var test = (text === undefined) ? "" : text.toLowerCase().toString()
                        if (test.match(".*ubuntu.*")) {
                            return "ubuntu.png"
                        } else if (test.match(".*linux.*")) {
                            return "linux.png"
                        } else {
                            return "reddit.png"
                        }
                    }

                    Action {
                        objectName: "sub1action"

                        visible: Storage.getSetting("initialized") !== "true" || Storage.getSetting("sub1") !== ""
                        text: Storage.getSetting("initialized") === "true" ? Storage.getSetting("sub1").toString() : "linux"
                        iconSource: Qt.resolvedUrl(toolbar.chooseIcon(text))
                        onTriggered: {
                            subreddittab.url = "/r/" + text
                            reloadTabs()
                        }
                    }
                    Action {
                        objectName: "sub2action"

                        visible: Storage.getSetting("initialized") !== "true" || Storage.getSetting("sub2") !== null
                        text: Storage.getSetting("initialized") === "true" ? Storage.getSetting("sub2").toString() : "pics"
                        iconSource: Qt.resolvedUrl(toolbar.chooseIcon(text))

                        onTriggered: {
                            subreddittab.url = "/r/" + text
                            reloadTabs()
                        }
                    }
                    Action {
                        objectName: "sub3action"

                        visible: Storage.getSetting("initialized") !== "true" || Storage.getSetting("sub3") !== null
                        text: Storage.getSetting("initialized") === "true" ? Storage.getSetting("sub3").toString() : "ubuntuphone"
                        iconSource: Qt.resolvedUrl(toolbar.chooseIcon(text))

                        onTriggered: {
                            subreddittab.url = "/r/" + text
                            reloadTabs()
                        }
                    }

                    Action {
                        objectName: "enter"

                        text: "?"
                        iconSource: Qt.resolvedUrl("reddit.png")

                        onTriggered: {
                            dialog.showSubredditPrompt()
                        }
                    }

                    Action {
                        objectName: "home"

                        text: "home"
                        iconSource: Qt.resolvedUrl("reddit.png")

                        onTriggered: {
                            if (flipablelink.flipped) {
                                var http = new XMLHttpRequest()
                                var voteurl = "http://www.reddit.com/api/vote"
                                var direction = (tools.children[4].iconSource.toString().match(".*upvote.png$")) ? "0" : "1"
                                var params = "dir=" + direction + "&id=" + backsidelink.thingname + "&uh="+Storage.getSetting("userhash")+"&api_type=json";
                                http.open("POST", voteurl, true);
                                console.debug(params)

                                // Send the proper header information along with the request
                                http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                                http.setRequestHeader("Content-length", params.length);
                                http.setRequestHeader("User-Agent", "Ubuntu Phone Reddit App 0.1")
                                http.setRequestHeader("Connection", "close");

                                http.onreadystatechange = function() {
                                    if (http.readyState == 4) {
                                        if (http.status == 200) {
                                            console.debug(http.responseText)
                                            var jsonresponse = JSON.parse(http.responseText)
                                            if (jsonresponse.json !== undefined) {
                                                console.debug("error")
                                            } else {
                                                console.debug("Upvoted!")
                                                backsidelink.likes = (tools.children[4].iconSource.toString().match(".*upvote.png$")) ? null : true
                                                tools.children[4].iconSource = (tools.children[4].iconSource.toString().match(".*upvote.png$")) ? "upvoteEmpty.png" : "upvote.png"
                                                tools.children[5].iconSource = "downvoteEmpty.png"

                                            }
                                        } else {
                                            console.debug("error: " + http.status)
                                        }
                                    }
                                }
                                http.send(params);
                            } else {
                                subreddittab.url = "/"
                                reloadTabs()
                            }
                        }
                    }

                    Action {
                        objectName: "settings"

                        visible: true
                        text: "settings"
                        iconSource: Qt.resolvedUrl("settings.png")

                        onTriggered: {
                            if (flipablelink.flipped) {
                                var http = new XMLHttpRequest()
                                var voteurl = "http://www.reddit.com/api/vote"
                                var direction = (tools.children[5].iconSource.toString().match(".*downvote.png$")) ? "0" : "-1"
                                var params = "dir=" + direction + "&id=" + backsidelink.thingname+"&uh=" + Storage.getSetting("userhash")+"&api_type=json";
                                http.open("POST", voteurl, true);
                                console.debug(params)

                                // Send the proper header information along with the request
                                http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                                http.setRequestHeader("Content-length", params.length);
                                http.setRequestHeader("User-Agent", "Ubuntu Phone Reddit App 0.1")
                                http.setRequestHeader("Connection", "close");

                                http.onreadystatechange = function() {
                                    if (http.readyState == 4) {
                                        if (http.status == 200) {
                                            console.debug(http.responseText)
                                            var jsonresponse = JSON.parse(http.responseText)
                                            if (jsonresponse.json !== undefined) {
                                                console.debug("error")
                                            } else {
                                                console.debug("Downvoted!")
                                                backsidelink.likes = (tools.children[5].iconSource.toString().match(".*downvote.png$")) ? null : false
                                                tools.children[4].iconSource = "upvoteEmpty.png"
                                                tools.children[5].iconSource = (tools.children[5].iconSource.toString().match(".*downvote.png$")) ? "downvoteEmpty.png" : "downvote.png"
                                            }
                                        } else {
                                            console.debug("error: " + http.status)
                                        }
                                    }
                                }
                                http.send(params);
                            } else {
                                tabs.selectedTabIndex++
                            }
                        }
                    }

                    Action {
                        objectName: "corneraction"

                        text: "login"
                        iconSource: Qt.resolvedUrl("avatar.png")

                        onTriggered: {
                            if (flipablelink.flipped && backsidelink.commentpage === true) {
                                pagestack.pop()
                                if (pagestack.depth === 1) {
                                    enabled = false
                                }
                            } else if (flipablelink.flipped) {
                                console.log("comments")
                                commentrectangle.loadPage(backsidelink.permalink, backsidelink.title)
                                backsidelink.commentpage = true
                                tools.children[4].visible = false
                                tools.children[5].visible = false
                                tools.children[6].visible = true
                                tools.children[6].text = "previous"
                                tools.children[6].enabled = false
                                tools.children[6].iconSource = Qt.resolvedUrl("previous.png")
                                tools.back.visible = true
                            } else {
                                login()
                            }
                        }
                    }

                    back {
                        visible: false
                        text: "return"
                        onTriggered: {
                            flipablelink.flip()
                            webview.url = "about:blank"
                            if (tools.children[0].text !== "") tools.children[0].visible = true
                            if (tools.children[1].text !== "") tools.children[1].visible = true
                            if (tools.children[2].text !== "") tools.children[2].visible = true
                            tools.children[3].visible = true
                            tools.children[4].visible = true
                            tools.children[4].enabled = true
                            tools.children[4].text = "home"
                            tools.children[4].iconSource = Qt.resolvedUrl("reddit.png")
                            tools.children[5].visible = true
                            tools.children[5].enabled = true
                            tools.children[5].text = "settings"
                            tools.children[5].iconSource = Qt.resolvedUrl("settings.png")
                            tools.children[6].visible = true
                            tools.children[6].enabled = true
                            tools.children[6].text = (Storage.getSetting("userhash") === "1") ? "login": "logout"
                            tools.children[6].iconSource = Qt.resolvedUrl("avatar.png")
                            tools.back.visible = false
                        }
                    }

                    lock: (Storage.getSetting("autohidetoolbar") !== "true")
                }

                Column {
                    anchors.centerIn: parent
                    Label {
                        id: label
                        objectName: "label"
                    }
                }
            }


            //	what are the real icon names for these?
            //	is it possible to see icon and title in the title bar?
            //	iconSource: (url == "/") ? "image://gicon/go-home" :
            //				(url == "/r/all") ? "image://gicon/help-about" : ""

            title: (url == "/") ? "reddit.com" : url.substring(1)

            function refreshTab() {
                linkslistmodel.source = "http://www.reddit.com" + subreddittab.url + ".json?uh="+Storage.getSetting("userhash")+"&api_type=json&limit=" + Js.getFetchedArray()[Storage.getSetting("numberfetchedposts")]
            }

            Flipable {
                id: flipablelink
                anchors.fill: parent
                property bool flipped: false

                //flipsvertically: false

                onFlippedChanged: {
                    if (!flipped) {
                        pagestack.clear()
                        webview.url = "about:blank"
                    }
                }
                function flip () {
                    flipablelink.flipped = !flipablelink.flipped
                }

                transform: Rotation {
                    id: linkrotation
                    origin.x: flipablelink.width / 2
                    origin.y: flipablelink.height / 2
                    axis.x: 0; axis.y: 1; axis.z: 0     // add option: which axis
                    angle: 0    // the default angle
                }

                states: State {
                    name: "back"
                    PropertyChanges { target: linkrotation; angle: 180 }
                    when: flipablelink.flipped
                }

                transitions: Transition {
                    NumberAnimation { target: linkrotation; property: "angle"; duration: (Storage.getSetting("flippages") != "true")? 0 : 200 }
                }

                JSONListModel {
                    id: linkslistmodel
                    source: (Storage.getSetting("initialized") === "true") ? "http://www.reddit.com/.json?uh=" + Storage.getSetting("userhash")+"&api_type=json&limit=" + Js.getFetchedArray()[Storage.getSetting("numberfetchedposts")]
                                                                           : "http://www.reddit.com/.json?api_type=json&limit=25"
                    query: "$.data.children[*]"
                }

                front: Rectangle {
                    anchors.fill: parent
                    enabled: !flipablelink.flipped

                    color: Js.getBackgroundColor()

                    GridView {
                        id: gridview
                        anchors.fill: parent
                        visible: (Storage.getSetting("enablethumbnails") === "true" && Storage.getSetting("gridthumbnails") === "true")
                        model: linkslistmodel.model
                        cellWidth: units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")])
                        cellHeight: units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")])
                        delegate: ListItem.Standard {
                            id: griditem
                            height: (Storage.getSetting("initialized") === "true") ? units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")]) : units.gu(6)
                            width: parent.width
                            UbuntuShape {
                                id: thumbshapegrid
                                height: parent.height
                                width: (Storage.getSetting("enablethumbnails") != "true") ? 0 : parent.height
                                anchors.left: (Storage.getSetting("thumbnailsonleftside") == "true") ? parent.left : undefined
                                anchors.right: (Storage.getSetting("thumbnailsonleftside") == "true") ? undefined : parent.right
                                radius: (Storage.getSetting("rounderthumbnails") == "true") ? "medium" : "small"

                                image: Image {
                                    id: gridthumbimage
                                    fillMode: Image.Stretch
                                    function chooseThumb () {
                                        if (model.data.is_self) {
                                            return ""
                                        } else if (model.data.thumbnail == "nsfw" || model.data.thumbnail == "" || model.data.thumbnail == "default") {
                                            return "link.png"
                                        } else {
                                            return model.data.thumbnail
                                        }
                                    }
                                    source: chooseThumb()
                                }
                                Text {
                                    id: gridalttext
                                    anchors.centerIn: parent
                                    opacity: (model.data.is_self) ? .4 : 0
                                    color: (Storage.getSetting("nightmode") == "true") ? "#FFFFFF" : "#000000"
                                    text: "Aa+"
                                    font.pixelSize: 22
                                }
                                Text {
                                    id: gridseenit
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    opacity: 0
                                    color: "green"
                                    text: "✓"
                                    font.pixelSize: 30
                                }
                                Text {
                                    id: gridnsfwtext
                                    anchors.centerIn: parent
                                    opacity: (model.data.thumbnail == "nsfw") ? .6 : 0
                                    color: (Storage.getSetting("nightmode") == "true") ? "#FFFFFF" : "#000000"
                                    font.bold: true
                                    text: "nsfw"
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        webview.url = model.data.url
                                        flipablelink.flipped = true
                                        backsidelink.commentpage = false
                                        backsidelink.permalink = model.data.permalink
                                        backsidelink.title = model.data.title
                                        backsidelink.likes = model.data.likes
                                        backsidelink.thingname = model.data.name
                                        tools.children[0].visible = false
                                        tools.children[1].visible = false
                                        tools.children[2].visible = false
                                        tools.children[3].visible = false
                                        tools.children[4].text = "upvote"
                                        tools.children[4].iconSource = Qt.resolvedUrl((model.data.likes === true) ? "upvote.png" : "upvoteEmpty.png")
                                        tools.children[5].text = "downvote"
                                        tools.children[5].iconSource = Qt.resolvedUrl((model.data.likes === false) ?  "downvote.png" : "downvoteEmpty.png")
                                        tools.children[6].text = "comments"
                                        tools.children[6].iconSource = Qt.resolvedUrl("comments.png")
                                        tools.back.visible = true
                                        gridseenit.opacity = 1
                                    }
                                    enabled: !flipablelink.flipped
                                }
                            }
                        }
                    }

                    ListView {
                        id: listview
                        anchors.fill: parent
                        visible: !(Storage.getSetting("enablethumbnails") === "true" && Storage.getSetting("gridthumbnails") === "true")
                        model: linkslistmodel.model

                        delegate: ListItem.Standard {
                            id: listitem
                            height: (Storage.getSetting("initialized") === "true") ? units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")]) : units.gu(6)
                            width: parent.width

                            UbuntuShape {
                                id: thumbshape
                                height: parent.height
                                width: (Storage.getSetting("enablethumbnails") != "true") ? 0 : parent.height
                                anchors.left: (Storage.getSetting("thumbnailsonleftside") == "true") ? parent.left : undefined
                                anchors.right: (Storage.getSetting("thumbnailsonleftside") == "true") ? undefined : parent.right
                                radius: (Storage.getSetting("rounderthumbnails") == "true") ? "medium" : "small"

                                image: Image {
                                    id: thumbimage
                                    fillMode: Image.Stretch
                                    opacity: (model.data.is_self) ? 0 : 1
                                    function chooseThumb () {
                                        if (model.data.is_self) {
                                            return ""
                                        } else if (model.data.thumbnail == "nsfw" || model.data.thumbnail == "" || model.data.thumbnail == "default") {
                                            return "link.png"
                                        } else {
                                            return model.data.thumbnail
                                        }
                                    }
                                    source: chooseThumb()
                                }
                                Text {
                                    id: alttext
                                    anchors.centerIn: parent
                                    opacity: (model.data.is_self) ? .4 : 0
                                    color: (Storage.getSetting("nightmode") == "true") ? "#FFFFFF" : "#000000"
                                    text: "Aa+"
                                    font.pixelSize: 22
                                }
                                Text {
                                    id: seenit
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    opacity: 0
                                    color: "green"
                                    text: "✓"
                                    font.pixelSize: 30
                                }
                                Text {
                                    id: nsfwtext
                                    anchors.centerIn: parent
                                    opacity: (model.data.thumbnail == "nsfw") ? .6 : 0
                                    color: (Storage.getSetting("nightmode") == "true") ? "#FFFFFF" : "#000000"
                                    font.bold: true
                                    text: "nsfw"
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (model.data.is_self) {
                                            // TODO: view just the selftext, not the actual url
                                            webview.url = model.data.url
                                        } else {
                                            webview.url = model.data.url
                                        }
                                        flipablelink.flipped = true
                                        backsidelink.commentpage = false
                                        backsidelink.permalink = model.data.permalink
                                        backsidelink.title = model.data.title
                                        backsidelink.likes = model.data.likes
                                        backsidelink.thingname = model.data.name
                                        tools.children[0].visible = false
                                        tools.children[1].visible = false
                                        tools.children[2].visible = false
                                        tools.children[3].visible = false
                                        tools.children[4].text = "upvote"
                                        tools.children[4].iconSource = Qt.resolvedUrl((model.data.likes === true) ? "upvote.png" : "upvoteEmpty.png")
                                        tools.children[5].text = "downvote"
                                        tools.children[5].iconSource = Qt.resolvedUrl((model.data.likes === false) ?  "downvote.png" : "downvoteEmpty.png")
                                        tools.children[6].text = "comments"
                                        tools.children[6].iconSource = Qt.resolvedUrl("comments.png")
                                        tools.back.visible = true
                                        frontsideitem.color = Js.getDimmedBackgroundColor()
                                        seenit.opacity = 1
                                    }
                                    enabled: !flipablelink.flipped
                                }
                            }

                            Rectangle {
                                id: itemrectangle
                                height: parent.height
                                width: parent.width - thumbshape.width
                                visible: !(Storage.getSetting("enablethumbnails") === "true" && Storage.getSetting("gridthumbnails") === "true")
                                enabled: !(Storage.getSetting("enablethumbnails") === "true" && Storage.getSetting("gridthumbnails") === "true")

                                anchors.left: (Storage.getSetting("thumbnailsonleftside") == "true") ? undefined : parent.left
                                anchors.right: (Storage.getSetting("thumbnailsonleftside") == "true") ? parent.right : undefined

                                color: Js.getBackgroundColor()

                                Flipable {
                                    id: itemflipable
                                    anchors.fill: parent

                                    property bool flipped: false

                                    front: Rectangle {
                                        id: frontsideitem
                                        anchors.fill: parent
                                        color: Js.getBackgroundColor()

                                        Label {
                                            width: parent.width
                                            text: model.data.title
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2

                                            font.pixelSize: parent.height / 4
                                        }

                                        Label {
                                            width: parent.width
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 1
                                            font.pixelSize: parent.height / 5

                                            anchors.bottom: parent.bottom
                                            //							anchors.left: thumbshape.right

                                            text: "Score: " + model.data.score +
                                                  " in r/" + model.data.subreddit +
                                                  " by " + model.data.author +
                                                  " (" + model.data.domain + ")"
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            enabled: !itemflipable.flipped
                                            onClicked: {
                                                // Flip item?
                                                // itemflipable.flip()

                                                // Go straight to comments?
                                                flipablelink.flip()
                                                commentrectangle.loadPage(model.data.permalink, model.data.title)
                                                backsidelink.commentpage = true
                                                backsidelink.permalink = model.data.permalink
                                                backsidelink.title = model.data.title
                                                backsidelink.likes = model.data.likes
                                                backsidelink.thingname = model.data.name
                                                tools.children[0].visible = false
                                                tools.children[1].visible = false
                                                tools.children[2].visible = false
                                                tools.children[3].visible = false
                                                tools.children[4].visible = false
                                                tools.children[5].visible = false
                                                tools.children[6].visible = true
                                                tools.children[6].text = "previous"
                                                tools.children[6].enabled = false
                                                tools.children[6].iconSource = Qt.resolvedUrl("previous.png")
                                                tools.back.visible = true
                                            }
                                        }
                                    }
                                }

                            }
                        }
                    }
                }

                back: Rectangle {
                    id: backsidelink

                    property bool commentpage: false
                    property bool likes: null
                    property string permalink: ""
                    property string title: ""
                    property string thingname: ""
                    property string urlviewing: ""

                    anchors.fill: parent
                    color: Js.getBackgroundColor()
                    enabled: flipablelink.flipped

                    Rectangle {
                        id: commentrectangle
                        opacity: (backsidelink.commentpage)? 1 : 0
                        color: Js.getBackgroundColor()

                        // why isn't this enabled?
                        // TODO: fix contents

                        height: parent.height
                        width: parent.width
                        anchors.top: parent.top

                        property string permalink: ""

                        function loadPage (n_permalink, title) {
                            permalink = n_permalink;
                            commentslistmodel.source = "http://www.reddit.com" + permalink + ".json"
                            pagestack.clear()
                            rootpage.title = title
                            pagestack.push(rootpage)
                            tools.children[6].enabled = false
                            tools.children[6].visible = true
                        }

                        JSONListModel {
                            id: commentslistmodel
                            query: "$[1].data.children[*]"
                        }

                        PageStack {
                            id: pagestack
                            anchors.fill: parent
                            Component.onCompleted: push(rootpage, [])

                            // try to merge these next 2
                            Page {
                                id: rootpage

                                ListView {
                                    anchors.fill: parent
                                    model: commentslistmodel.model

                                    delegate: ListItem.Standard {
                                        width: parent.width
                                        Text {
                                            anchors.top: parent.top
                                            anchors.topMargin: 10
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            id: commenttext
                                            width: parent.width - 50
                                            text: model.data.body
                                            wrapMode: Text.WordWrap
                                            color: (Storage.getSetting("nightmode") == "true") ? "#FFFFFF" : "#000000"
                                            opacity: .6
                                        }

                                        progression: (model.data.replies === "") ? false : true
                                        highlightWhenPressed: false

                                        onClicked: {
                                            if (model.data.replies !== "") {
                                                pagestack.push(newpage, {commentsModel: model.data.replies.data.children})
                                                tools.children[6].enabled = true
                                            }
                                        }
                                        Component.onCompleted: {
                                            height = commenttext.paintedHeight + 20
                                        }
                                    }
                                }
                            }

                            Component {
                                id: newpage

                                Page {
                                    id: page
                                    title: rootpage.title

                                    property variant commentsModel: []

                                    ListView {
                                        anchors.fill: parent
                                        model: commentsModel

                                        delegate: ListItem.Standard {
                                            Text {
                                                anchors.top: parent.top
                                                anchors.topMargin: 10
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10
                                                id: commentreplytext
                                                width: parent.width - 40
                                                text: modelData.data.body
                                                wrapMode: Text.WordWrap
                                                color: (Storage.getSetting("nightmode") == "true") ? "#FFFFFF" : "#000000"
                                                opacity: .6
                                            }

                                            progression: (modelData.data.replies === "") ? false : true
                                            highlightWhenPressed: false

                                            onClicked: {
                                                if (modelData.data.replies !== "") {
                                                    pagestack.push(newpage, {commentsModel: modelData.data.replies.data.children})
                                                }
                                            }
                                            Component.onCompleted: {
                                                height = commentreplytext.paintedHeight + 20
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: linkrectangle
                        opacity: (backsidelink.commentpage)? 0 : 1
                        enabled: (backsidelink.commentpage)? 0 : 1

                        height: parent.height
                        width: parent.width
                        anchors.top: parent.top

                        WebView {
                            id: webview
                            anchors.fill: parent

                            url: backsidelink.urlviewing
                            smooth: true
                        }
                    }
                }
            }
        }

        // Second tab begins here
        Tab {
            id: settingstab
            anchors.fill: parent
            title: "Settings"
            page: Page {
                id: settingspage
                Component.onCompleted: {
                    if (Storage.getSetting("initialized") !== "true") {
                        // initialize settings
                        console.debug("settings not initialized on subreddit load")
                    }
                    Storage.setSetting("userhash", 1)
                }

                tools: ToolbarActions {
                    id: settingstoolbar
                    active: true

                    Action {
                        objectName: "account"

                        visible: true
                        text: "account"
                        iconSource: Qt.resolvedUrl("avatar.png")

                        onTriggered: {
                            backside.loadLogin()
                        }
                    }

                    Action {
                        objectName: "subreddits"

                        visible: true
                        text: "subreddits"
                        iconSource: Qt.resolvedUrl("reddit.png")

                        onTriggered: {
                            backside.loadSubreddits()
                        }
                    }

                    back {
                        visible: true
                        onTriggered: {
                            if (flipable.flipped) {
                                flipable.flip()
                            } else {
                                tabs.selectedTabIndex--
                            }
                        }
                    }
                    lock: true
                }

                MyFlipable {
                    id: flipable
                    anchors.fill: parent

                    flipsvertically: false

                    front: Rectangle {
                        id: frontside
                        anchors.fill: parent

                        color: Js.getBackgroundColor()
                        enabled: !flipable.flipped

                        Column {
                            anchors.fill: parent

                            Component.onCompleted: {
                                Storage.initialize()
                                console.debug("INITIALIZED")
                                if (Storage.getSetting("initialized") !== "true") {
                                    // initialize settings
                                    console.debug("reset settings")
                                    Storage.setSetting("initialized", "true")
                                    Storage.setSetting("numberfetchedposts", "2")
                                    Storage.setSetting("numberfetchedcomments", "2")
                                    Storage.setSetting("enablethumbnails", "true")
                                    Storage.setSetting("thumbnailsonleftside", "true")
                                    Storage.setSetting("rounderthumbnails", "false")
                                    Storage.setSetting("gridthumbnails", "false")
                                    Storage.setSetting("postheight", "0")
                                    Storage.setSetting("nightmode", "false")
                                    Storage.setSetting("flippages", "true")
                                    Storage.setSetting("autologin", "false")
                                    Storage.setSetting("sub1", "linux")
                                    Storage.setSetting("sub2", "pics")
                                    Storage.setSetting("sub3", "ubuntuphone")
                                    Storage.setSetting("accountname", "")
                                    Storage.setSetting("password", "")
                                    Storage.setSetting("autohidetoolbar", "false")
                                    reloadTabs()
                                }
                                numberfetchedposts.selectedIndex = parseInt(Storage.getSetting("numberfetchedposts"))
                                numberfetchedcomments.selectedIndex = parseInt(Storage.getSetting("numberfetchedcomments"))
                                // account...
                                // subreddits...
                                enablethumbnails.loadValue()
                                thumbnailsonleftside.loadValue()
                                rounderthumbnails.loadValue()
                                gridthumbnails.loadValue()
                                postheight.selectedIndex = parseInt(Storage.getSetting("postheight"))
                                nightmode.loadValue()
                                flippages.loadValue()
                                autologin.loadValue()
                                autohidetoolbar.loadValue()
                                sub1.text = (Storage.getSetting("sub1") === null) ? "" : Storage.getSetting("sub1")
                                sub2.text = (Storage.getSetting("sub2") === null) ? "" : Storage.getSetting("sub2")
                                sub3.text = (Storage.getSetting("sub3") === null) ? "" : Storage.getSetting("sub3")
                            }

                            ListItem.ValueSelector {
                                id: numberfetchedposts
                                text: "Number of fetched posts"

                                property string value: values[selectedIndex]

                                values: Js.getFetchedArray()

                                onSelectedIndexChanged: Storage.setSetting("numberfetchedposts", selectedIndex)
                            }

                            ListItem.ValueSelector {
                                id: postheight
                                text: "Relative size of posts"

                                values: Js.getPostHeightArray()

                                onSelectedIndexChanged: Storage.setSetting("postheight", selectedIndex)
                            }

                            ListItem.ValueSelector {
                                id: numberfetchedcomments
                                text: "Number of fetched comments"

                                values: Js.getFetchedArray()

                                onSelectedIndexChanged: Storage.setSetting("numberfetchedcomments", selectedIndex)
                            }

                            ListItem.Standard {
                                text: "Enable thumbnails"
                                height: units.gu(5)

                                control: SettingSwitch {
                                    anchors.centerIn: parent
                                    id: enablethumbnails
                                    name: "enablethumbnails"
                                    onCheckedChanged: {
                                        gridview.visible = gridthumbnails.checked && enablethumbnails.checked
                                        listview.visible = !gridview.visible
                                        reloadTabs()
                                    }
                                }
                            }

                            ListItem.Standard {
                                text: "Display thumbnails on left side"
                                enabled: enablethumbnails.checked
                                height: units.gu(5)

                                control: SettingSwitch {
                                    anchors.centerIn: parent
                                    id: thumbnailsonleftside
                                    name: "thumbnailsonleftside"
                                    onCheckedChanged: {
                                        reloadTabs()
                                    }
                                }
                            }

                            ListItem.Standard {
                                text: "Rounder thumbnails"
                                enabled: enablethumbnails.checked
                                height: units.gu(5)

                                control: SettingSwitch {
                                    anchors.centerIn: parent
                                    id: rounderthumbnails
                                    name: "rounderthumbnails"
                                    onCheckedChanged: {
                                        reloadTabs()
                                    }
                                }
                            }

                            ListItem.Standard {
                                text: "Gallery/grid view of thumbnails"
                                enabled: enablethumbnails.checked
                                height: units.gu(5)

                                control: SettingSwitch {
                                    anchors.centerIn: parent
                                    id: gridthumbnails
                                    name: "gridthumbnails"
                                    onCheckedChanged: {
                                        gridview.visible = gridthumbnails.checked && enablethumbnails.checked
                                        listview.visible = !gridview.visible
                                        reloadTabs()
                                    }
                                }
                            }

                            ListItem.Standard {
                                text: "Flip pages"
                                height: units.gu(5)

                                control: SettingSwitch {
                                    anchors.centerIn: parent
                                    id: flippages
                                    name: "flippages"
                                }
                            }

                            ListItem.Standard {
                                text: "Night mode"
                                height: units.gu(5)

                                control: SettingSwitch {
                                    anchors.centerIn: parent
                                    id: nightmode
                                    name: "nightmode"
                                }
                            }

                            ListItem.Standard {
                                text: "Autohide main toolbar"
                                height: units.gu(5)

                                control: SettingSwitch {
                                    anchors.centerIn: parent
                                    id: autohidetoolbar
                                    name: "autohidetoolbar"
                                    onCheckedChanged: {
                                        toolbar.lock = (!autohidetoolbar.checked)
                                    }
                                }
                            }

                            ListItem.Standard {
                                //width: parent.width
                                height: units.gu(5)

                                text: "Note: app will need to be restarted\nfor changes to take effect."
                                opacity: .6
                            }
                        }
                    }

                    back: Rectangle {
                        id: backside

                        anchors.fill: parent
                        color: Js.getBackgroundColor()
                        enabled: flipable.flipped

                        function loadLogin () {
                            loginpage.visible = true
                            subredditlist.visible = false

                            flipable.flipped = true
                        }

                        function loadSubreddits () {
                            loginpage.visible = false
                            subredditlist.visible = true

                            flipable.flipped = true
                        }

                        property bool commentpage: false
                        property string urlviewing: ""

                        Rectangle {
                            height: parent.height
                            width: parent.width
                            anchors.bottom: parent.bottom
                            color: parent.color

                            Rectangle {
                                id: loginpage
                                opacity: 1

                                anchors.fill: parent
                                color: parent.color

                                Column {
                                    anchors.fill:parent

                                    ListItem.Empty {
                                        width: parent.width
                                        height: accounttextfield.height

                                        TextField {
                                            id: accounttextfield

                                            width: parent.width
                                            height: units.gu(8)

                                            placeholderText: "username"
                                            text: (Storage.getSetting("accountname") !== null) ? Storage.getSetting("accountname") : null

                                            onTextChanged: Storage.setSetting("accountname", text)

                                            enabled: true

                                            font.pixelSize: parent.height / 2
                                        }
                                    }

                                    ListItem.Empty {
                                        width: parent.width
                                        height: passwordtextfield.height

                                        TextField {
                                            id: passwordtextfield

                                            width: parent.width
                                            height: accounttextfield.height

                                            placeholderText: "password"
                                            text: (Storage.getSetting("password") !== null) ? Storage.getSetting("password") : null

                                            onTextChanged: Storage.setSetting("password", text)

                                            enabled: true

                                            echoMode: TextInput.Password
                                            font.pixelSize: parent.height / 2
                                        }
                                    }
                                    Button {
                                        id: loginbutton
                                        text: "login"
                                        height: units.gu(4)
                                        width: parent.width
                                        onClicked: {
                                            loginstatus.text = "waiting..."

                                            var http = new XMLHttpRequest()
                                            var loginurl = "https://ssl.reddit.com/api/login";
                                            var params = "user="+Storage.getSetting("accountname")+"&passwd="+Storage.getSetting("password")+"&api_type=json";
                                            http.open("POST", loginurl, true);

                                            // Only display params, with password, if needed.
                                            // console.debug(params)

                                            // Send the proper header information along with the request
                                            http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                                            http.setRequestHeader("Content-length", params.length);
                                            http.setRequestHeader("User-Agent", "Ubuntu Phone Reddit App 0.1")
                                            http.setRequestHeader("Connection", "close");

                                            http.onreadystatechange = function() {
                                                if (http.readyState == 4) {
                                                    if (http.status == 200) {
                                                        console.debug(http.responseText)
                                                        var jsonresponse = JSON.parse(http.responseText)
                                                        if (jsonresponse.json.data === undefined) {
                                                            loginstatus.text = "failed, try again" + "\n" + jsonresponse["json"]["errors"]
                                                            console.debug("error")
                                                        } else {
                                                            // store this user mod hash to pass to later api methods that require you to be logged in
                                                            Storage.setSetting("userhash", jsonresponse["json"]["data"]["modhash"])
                                                            loginstatus.text = "log in successful"
                                                            toolbar.children[6].text = "logout"
                                                            console.debug("success")
                                                            reloadTabs()
                                                        }
                                                    } else {
                                                        console.debug("error: " + http.status)
                                                        loginstatus.text = "failed, try again"
                                                    }
                                                }
                                            }
                                            http.send(params);
                                        }
                                    }
                                    ListItem.Standard {
                                        text: "Automatically log in when app starts"
                                        height: units.gu(5)

                                        control: SettingSwitch {
                                            anchors.centerIn: parent
                                            id: autologin
                                            name: "autologin"
                                        }
                                    }
                                    ListItem.Standard {
                                        id: loginstatus
                                        text: ""
                                        enabled: true
                                    }
                                }
                            }
                            Rectangle {
                                id: subredditlist

                                anchors.fill: parent
                                color: Js.getBackgroundColor()

                                Column {
                                    anchors.fill:parent
                                    id: subredditColumn
                                    function stripSlashes (text) {
                                        var split = text.toLowerCase().split("/")
                                        var i = 0
                                        for (; split.length; i++) {
                                            if ( split[i] !== "" && split[i] !== null && split[i] !== "r") break
                                        }
                                        if (split[i] !== null && split.length > i && split[i].length > 0) {
                                            return split[i]
                                        } else {
                                            return ""
                                        }
                                    }

                                    ListItem.Empty {
                                        width: parent.width
                                        height: units.gu(8)

                                        TextField {
                                            id: sub1
                                            width: parent.width
                                            height: units.gu(8)
                                            text: Storage.getSetting("sub1")
                                            onTextChanged: {
                                                Storage.setSetting("sub1", subredditColumn.stripSlashes(text))
                                                if (subredditColumn.stripSlashes(text) !== "") {
                                                    subredditpage.tools.children[0].visible = true
                                                    subredditpage.tools.children[0].iconSource = Qt.resolvedUrl(toolbar.chooseIcon(subredditColumn.stripSlashes(text)))
                                                    subredditpage.tools.children[0].text = subredditColumn.stripSlashes(text)
                                                } else {
                                                    subredditpage.tools.children[0].visible = false
                                                    subredditpage.tools.children[0].text = ""
                                                }
                                            }
                                            enabled: true
                                            font.pixelSize: parent.height / 2
                                        }
                                    }

                                    ListItem.Empty {
                                        width: parent.width
                                        height: units.gu(8)

                                        TextField {
                                            id: sub2
                                            width: parent.width
                                            height: units.gu(8)
                                            text: Storage.getSetting("sub2")
                                            onTextChanged: {
                                                Storage.setSetting("sub2", subredditColumn.stripSlashes(text))
                                                if (subredditColumn.stripSlashes(text) !== "") {
                                                    subredditpage.tools.children[1].visible = true
                                                    subredditpage.tools.children[1].iconSource = Qt.resolvedUrl(toolbar.chooseIcon(subredditColumn.stripSlashes(text)))
                                                    subredditpage.tools.children[1].text = subredditColumn.stripSlashes(text)
                                                } else {
                                                    subredditpage.tools.children[1].visible = false
                                                    subredditpage.tools.children[1].text = ""
                                                }
                                            }
                                            enabled: true
                                            font.pixelSize: parent.height / 2
                                        }
                                    }

                                    ListItem.Empty {
                                        width: parent.width
                                        height: units.gu(8)

                                        TextField {
                                            id: sub3
                                            width: parent.width
                                            height: units.gu(8)
                                            text:  Storage.getSetting("sub3")
                                            onTextChanged: {
                                                Storage.setSetting("sub3", subredditColumn.stripSlashes(text))
                                                if (subredditColumn.stripSlashes(text) !== "") {
                                                    subredditpage.tools.children[2].visible = true
                                                    subredditpage.tools.children[2].iconSource = Qt.resolvedUrl(toolbar.chooseIcon(subredditColumn.stripSlashes(text)))
                                                    subredditpage.tools.children[2].text = subredditColumn.stripSlashes(text)
                                                } else {
                                                    subredditpage.tools.children[2].visible = false
                                                    subredditpage.tools.children[2].text = ""
                                                }
                                            }
                                            enabled: true
                                            font.pixelSize: parent.height / 2
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function reloadTabs() {
        console.debug("in reddit.qml reloadTabs()")
        subreddittab.refreshTab()
    }

    function login() {
        if (tools.children[6].text === "logout") {
            Storage.setSetting("userhash", 1)
            tools.children[6].text = "login"
            reloadTabs()
        } else {

            var http = new XMLHttpRequest()
            var loginurl = "https://ssl.reddit.com/api/login";
            var params = "user="+Storage.getSetting("accountname")+"&passwd="+Storage.getSetting("password")+"&api_type=json";
            http.open("POST", loginurl, true);

            // Only display params, with password, if needed.
            // console.debug(params)

            // Send the proper header information along with the request
            http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            http.setRequestHeader("Content-length", params.length);
            http.setRequestHeader("User-Agent", "Ubuntu Phone Reddit App 0.1")
            http.setRequestHeader("Connection", "close");

            http.onreadystatechange = function() {
                if (http.readyState == 4) {
                    if (http.status == 200) {
                        console.debug(http.responseText)
                        var jsonresponse = JSON.parse(http.responseText)
                        if (jsonresponse.json.data === undefined) {
                            console.debug("error")
                            dialog.showLoginPrompt()
                        } else {
                            // store this user mod hash to pass to later api methods that require you to be logged in
                            Storage.setSetting("userhash", jsonresponse["json"]["data"]["modhash"])
                            console.debug("success")
                            tools.children[6].text = "logout"
                            reloadTabs()
                        }
                    } else {
                        console.debug("error: " + http.status)
                        dialog.showLoginPrompt()
                    }
                }
            }
            http.send(params);
        }
    }
}
