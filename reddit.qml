import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import QtWebKit 3.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import "storage.js" as Storage
import "javascript.js" as Js

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "reddit"
    width: units.gu(45)
    height: units.gu(80)
    id: mainView

    property string url: "/"


    Component.onCompleted: {
        if (Storage.getSetting("autologin") == "true") {
            login()
        }
    }

    PageStack {
        id: mainPageStack
        anchors.fill: parent

        Component.onCompleted: {
            mainPageStack.push(subredditpage)
            if (Storage.getSetting("initialized") !== "true") {
                // initialize settings
                console.debug("settings not initialized on subreddit load")
            }
            Storage.setSetting("userhash", 1)
        }

        Page {
            id: subredditpage
            width: mainView.width
            height: mainView.height
            title: (url == "/") ? "reddit.com" : url.substring(1)

            Item {
                id: dialog

                anchors.fill: parent
                z: 1000

                // We want to be a child of the root item so that we can cover
                // the whole scene with our "dim" overlay.
                parent: mainView

                default property alias __children: dynamicColumn.children

                function showAccountPrompt () {
                    passwordPrompt.visible = false
                    accountPrompt.visible = true
                    loginFailed.visible = false
                    gotoSub.visible = false
                    dialogWindow.visible = true
                    dimBackground.visible = true
                    mouseBlocker.visible = true
                }
                function showPasswordPrompt () {
                    passwordPrompt.visible = true
                    accountPrompt.visible = false
                    loginFailed.visible = false
                    gotoSub.visible = false
                    dialogWindow.visible = true
                    dimBackground.visible = true
                    mouseBlocker.visible = true
                }
                function showSubredditPrompt () {
                    passwordPrompt.visible = false
                    accountPrompt.visible = false
                    loginFailed.visible = false
                    gotoSub.visible = true
                    dialogWindow.visible = true
                    dimBackground.visible = true
                    mouseBlocker.visible = true
                }
                function showLoginFailed () {
                    passwordPrompt.visible = false
                    accountPrompt.visible = false
                    loginFailed.visible = true
                    gotoSub.visible = false
                    dialogWindow.visible = true
                    dimBackground.visible = true
                    mouseBlocker.visible = true
                }
                function hidePrompt () {
                    passwordPrompt.visible = false
                    accountPrompt.visible = false
                    loginFailed.visible = false
                    gotoSub.visible = false
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
                            id: loginFailed
                            anchors.centerIn: parent
                            anchors.fill: parent

                            Text {
                                id: loginFailedText

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
                            id: gotoSub
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
                                    mainView.url = "/"
                                    if (subreddittextfield.text !== "") {
                                        var split = subreddittextfield.text.split("/")
                                        var i = 0
                                        for (; split.length; i++) {
                                            if ( split[i] !== "" && split[i] !== null && split[i] !== "r") break
                                        }
                                        if (split[i] !== null && split.length > i && split[i].length > 0) {
                                            mainView.url = "/r/" + split[i]
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

                        Rectangle {
                            id: passwordPrompt
                            anchors.centerIn: parent
                            anchors.fill: parent

                            TextField {
                                id: password
                                width: parent.width
                                height: units.gu(8)
                                placeholderText: "password"
                                enabled: parent.visible
                                echoMode: TextInput.Password
                                font.pixelSize: 20
                            }
                            Button {
                                id: passwordpromptokbutton
                                text: "ok"
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                height: units.gu(4)
                                width: parent.width / 2
                                onClicked: {
                                    login(Storage.getSetting("accountname"), password.text)
                                    dialog.hidePrompt()
                                }
                            }

                            Button {
                                id: passwordpromptcancelbutton
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

                        Rectangle {
                            id: accountPrompt
                            anchors.centerIn: parent
                            anchors.fill: parent

                            TextField {
                                id: accountText
                                width: parent.width
                                height: units.gu(6)
                                placeholderText: "username"
                                enabled: parent.visible
                                font.pixelSize: 20
                            }

                            TextField {
                                id: passwordText
                                width: parent.width
                                height: units.gu(6)
                                anchors.top: accountText.bottom
                                placeholderText: "password"
                                enabled: parent.visible
                                echoMode: TextInput.Password
                                font.pixelSize: 20
                            }
                            Button {
                                id: accountpromptokbutton
                                text: "ok"
                                anchors.top: passwordText.bottom
                                anchors.left: parent.left
                                height: units.gu(4)
                                width: parent.width / 2
                                onClicked: {
                                    login(accountText.text, passwordText.text)
                                    dialog.hidePrompt()
                                }
                            }
                            Button {
                                id: accountpromptcancelbutton
                                text: "cancel"
                                anchors.top: passwordText.bottom
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

            Component.onCompleted: {
                if (Storage.getSetting("initialized") !== "true") {
                    // initialize settings
                    console.debug("settings not initialized on subreddit load")
                }
            }

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

            tools: ToolbarActions {
                id: subredditpagetoolbar
                active: true
                lock: Storage.getSetting("autohidetoolbar") === "false"

                Action {
                    objectName: "sub1action"

                    visible: Storage.getSetting("initialized") !== "true" || Storage.getSetting("sub1") !== ""
                    text: Storage.getSetting("initialized") === "true" ? Storage.getSetting("sub1").toString() : "linux"
                    iconSource: Qt.resolvedUrl(subredditpage.chooseIcon(text))
                    onTriggered: {
                        mainView.url = "/r/" + text
                        reloadTabs()
                    }
                }
                Action {
                    objectName: "sub2action"

                    visible: Storage.getSetting("initialized") !== "true" || Storage.getSetting("sub2") !== null
                    text: Storage.getSetting("initialized") === "true" ? Storage.getSetting("sub2").toString() : "pics"
                    iconSource: Qt.resolvedUrl(subredditpage.chooseIcon(text))

                    onTriggered: {
                        mainView.url = "/r/" + text
                        reloadTabs()
                    }
                }
                Action {
                    objectName: "sub3action"

                    visible: Storage.getSetting("initialized") !== "true" || Storage.getSetting("sub3") !== null
                    text: Storage.getSetting("initialized") === "true" ? Storage.getSetting("sub3").toString() : "ubuntuphone"
                    iconSource: Qt.resolvedUrl(subredditpage.chooseIcon(text))

                    onTriggered: {
                        mainView.url = "/r/" + text
                        reloadTabs()
                    }
                }

                Action {
                    objectName: "enter"

                    text: "find"
                    iconSource: "image://gicon/edit-find-symbolic"

                    onTriggered: {
                        dialog.showSubredditPrompt()
                    }
                }

                Action {
                    objectName: "home"

                    text: "home"
                    iconSource: "image://gicon/go-home-symbolic"

                    onTriggered: {
                        mainView.url = "/"
                        reloadTabs()
                    }
                }

                Action {
                    objectName: "settings"

                    visible: true
                    text: "settings"
                    iconSource: Qt.resolvedUrl("settings.png")

                    onTriggered: {
                        mainPageStack.push(settingspage)
                    }
                }

                Action {
                    objectName: "login"

                    text: "login"
                    iconSource: Qt.resolvedUrl("avatar.png")

                    onTriggered: {
                        if (subredditpage.tools.children[6].text === "logout") {
                            Storage.setSetting("userhash", 1)
                            subredditpage.tools.children[6].text = "login"
                            reloadTabs()
                        } else if (Storage.getSetting("accountname") === "") {
                            dialog.showAccountPrompt()
                        } else if (Storage.getSetting("password") === "") {
                            dialog.showPasswordPrompt()
                        } else {
                            login()
                        }
                    }
                }
            }

            Rectangle {
                color: Js.getBackgroundColor()
                anchors.fill: parent
            }

            function refreshTab() {
                linkslistmodel.source = "http://www.reddit.com" + mainView.url + ".json?uh="+Storage.getSetting("userhash")+"&api_type=json&limit=100"
                timer.start()
            }

            JSONListModel {
                id: linkslistmodel
                source: (Storage.getSetting("initialized") === "true") ? "http://www.reddit.com/.json?uh=" + Storage.getSetting("userhash")+"&api_type=json&limit=100"
                                                                       : "http://www.reddit.com/.json?api_type=json&limit=100"
                query: "$.data.children[*]"
            }

            JSONListModel {
                id: appendmodel
                source: (Storage.getSetting("initialized") === "true") ? "http://www.reddit.com/.json?uh=" + Storage.getSetting("userhash")+"&api_type=json&limit=100"
                                                                       : "http://www.reddit.com/.json?api_type=json&limit=100"
                query: "$.data.children[*]"
            }

            GridView {
                id: listview
                width: mainView.width
                height: mainView.height
                model: linkslistmodel.model
                cellHeight: (Storage.getSetting("initialized") === "true") ? units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")]) : units.gu(6)
                cellWidth: (Storage.getSetting("enablethumbnails") === "true" && Storage.getSetting("gridthumbnails") === "true") ? cellHeight : mainView.width

                Timer {
                    id: timer
                    interval: 2000; repeat: false
                    running: true
                    triggeredOnStart: true

                    onTriggered: {
                        var j = JSON.parse(linkslistmodel.json)
                        console.log(" j.data.after " +  j.data.after)
                        appendmodel.source = linkslistmodel.source + "&after=" + j.data.after
                        console.log("appendmodel.source " + appendmodel.source)
                    }
                }

                onMovementEnded: {
                    if(atYEnd) {
                        var j = JSON.parse(appendmodel.json)
                        var k = JSON.parse(linkslistmodel.json)
                        if(j.data.after !== k.data.after) {
                            for (var i = 0; i < appendmodel.model.count; i++) {
                                linkslistmodel.model.append(appendmodel.model.get(i))
                            }
                            appendmodel.source = linkslistmodel.source + "&after=" + j.data.after
                        }
                    }
                }

                delegate: Item {
                    id: delegates
                    height: (Storage.getSetting("initialized") === "true") ? units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")]) : units.gu(6)
                    width: parent.width

                    Component {
                        id: listdel
                        ListItem.Standard {
                            id: listitem
                            height: (Storage.getSetting("initialized") === "true") ? units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")]) : units.gu(6)
                            width: mainView.width
                            Rectangle {
                                id: background
                                color: Js.getBackgroundColor()
                                anchors.fill: parent
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
                                                linkpage.urlviewing = model.data.url
                                                mainPageStack.push(linkpage)
                                            } else {
                                                linkpage.urlviewing = model.data.url
                                                mainPageStack.push(linkpage)
                                            }
                                            console.log("image clicked")
                                            linkpage.permalink = model.data.permalink
                                            linkpage.title = model.data.title
                                            linkpage.likes = model.data.likes.toString()
                                            linktoolbar.children[0].iconSource = (linkpage.likes === "true" ? Qt.resolvedUrl("upvote.png") : Qt.resolvedUrl("upvoteEmpty.png"))
                                            linktoolbar.children[1].iconSource = (linkpage.likes === "false" ? Qt.resolvedUrl("downvote.png") : Qt.resolvedUrl("downvoteEmpty.png"))
                                            linkpage.thingname = model.data.name
                                            itemrectangle.color = Js.getDimmedBackgroundColor()
                                            seenit.opacity = 1
                                        }
                                    }
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

                                    text: "Score: " + model.data.score +
                                          " in r/" + model.data.subreddit +
                                          " by " + model.data.author +
                                          " (" + model.data.domain + ")"
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    enabled: true
                                    onClicked: {
                                        mainPageStack.push(commentpage)
                                        console.log("item clicked")
                                        commentslistmodel.source = ""
                                        commentpage.permalink = model.data.permalink
                                        commentpage.title = model.data.title
                                        commentpage.likes = model.data.likes.toString()
                                        commentpage.thingname = model.data.name
                                        commentslistmodel.source = "http://www.reddit.com" + commentpage.permalink + ".json"
                                    }
                                }
                            }
                        }
                    }

                    Component {
                        id: griddel

                        Item {
                            id: griditem
                            height: (Storage.getSetting("initialized") === "true") ? units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")]) : units.gu(6)
                            width: (Storage.getSetting("initialized") === "true") ? units.gu(Js.getPostHeightArray()[Storage.getSetting("postheight")]) : units.gu(6)
                            Rectangle {
                                id: background
                                color: Js.getBackgroundColor()
                                anchors.fill: parent
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
                                        mainPageStack.push(linkpage)
                                        linkpage.urlviewing = model.data.url
                                        linkpage.permalink = model.data.permalink
                                        linkpage.title = model.data.title
                                        linkpage.likes = model.data.likes.toString()
                                        linktoolbar.children[0].iconSource = (linkpage.likes === "true" ? Qt.resolvedUrl("upvote.png") : Qt.resolvedUrl("upvoteEmpty.png"))
                                        linktoolbar.children[1].iconSource = (linkpage.likes === "false" ? Qt.resolvedUrl("downvote.png") : Qt.resolvedUrl("downvoteEmpty.png"))
                                        linkpage.thingname = model.data.name
                                        gridseenit.opacity = 1
                                    }
                                }
                            }

                        }
                    }
                    Loader {
                        id: loaddelegate
                        sourceComponent: (Storage.getSetting("gridthumbnails") === "true") && (Storage.getSetting("enablethumbnails") === "true")? griddel : listdel
                    }
                }
            }
        }
        Page {
            id: commentpage

            property string likes: null
            property string permalink: ""
            property string thingname: ""
            property string urlviewing: ""

            JSONListModel {
                id: commentslistmodel
                query: "$[1].data.children[*]"
            }

            tools: ToolbarActions {
                id: commenttoolbar
                active: true
                lock: true
            }
            Rectangle {
                id: commentbackground
                color: Js.getBackgroundColor()
                anchors.fill: parent

                ListView {
                    model: commentslistmodel.model
                    width: mainView.width
                    height: mainView.height

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
                                mainPageStack.push(newpage, {commentsModel: model.data.replies.data.children})
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
                    title: commentpage.title

                    property variant commentsModel: []

                    tools: ToolbarActions {
                        id: commenttoolbar
                        active: true
                        lock: true

                        Action {
                            objectName: "previous"
                            enabled: true

                            text: "previous"
                            iconSource: Qt.resolvedUrl("previous.png")

                            onTriggered: {
                                mainPageStack.pop()
                            }
                        }

                        back {
                            visible: true
                            text: "Back"
                            onTriggered: {
                                mainPageStack.pop(subredditpage)
                            }
                        }
                    }
                    Rectangle {
                        id: commentbackground
                        color: Js.getBackgroundColor()
                        anchors.fill: parent

                        ListView {
                            width: mainView.width
                            height: mainView.height
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
                                        mainPageStack.push(newpage, {commentsModel: modelData.data.replies.data.children})
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
        Page {
            id: linkpage
            tools: ToolbarActions {
                id: linktoolbar

                Action {
                    objectName: "upvote"

                    text: "upvote"
                    iconSource: linkpage.likes === "true" ? Qt.resolvedUrl("upvote.png") : Qt.resolvedUrl("upvoteEmpty.png")

                    onTriggered: {
                        var http = new XMLHttpRequest()
                        var voteurl = "http://www.reddit.com/api/vote"
                        var direction = (linktoolbar.children[0].iconSource.toString().match(".*upvote.png$")) ? "0" : "1"
                        var params = "dir=" + direction + "&id=" + linkpage.thingname + "&uh="+Storage.getSetting("userhash")+"&api_type=json";
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
                                        linkpage.likes = (linktoolbar.children[0].iconSource.toString().match(".*upvote.png$")) ? "null" : "true"
                                        linktoolbar.children[0].iconSource = (linktoolbar.children[0].iconSource.toString().match(".*upvote.png$")) ? "upvoteEmpty.png" : "upvote.png"
                                        linktoolbar.children[1].iconSource = "downvoteEmpty.png"

                                    }
                                } else {
                                    console.debug("error: " + http.status)
                                }
                            }
                        }
                        http.send(params);

                    }
                }

                Action {
                    objectName: "downvote"

                    visible: true
                    text: "downvote"
                    iconSource: linkpage.likes === "false" ? Qt.resolvedUrl("downvote.png") : Qt.resolvedUrl("downvoteEmpty.png")

                    onTriggered: {
                        var http = new XMLHttpRequest()
                        var voteurl = "http://www.reddit.com/api/vote"
                        var direction = (linktoolbar.children[1].iconSource.toString().match(".*downvote.png$")) ? "0" : "-1"
                        var params = "dir=" + direction + "&id=" + linkpage.thingname+"&uh=" + Storage.getSetting("userhash")+"&api_type=json";
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
                                        linkpage.likes = (linktoolbar.children[1].iconSource.toString().match(".*downvote.png$")) ? "null" : "false"
                                        linktoolbar.children[0].iconSource = "upvoteEmpty.png"
                                        linktoolbar.children[1].iconSource = (linktoolbar.children[1].iconSource.toString().match(".*downvote.png$")) ? "downvoteEmpty.png" : "downvote.png"
                                    }
                                } else {
                                    console.debug("error: " + http.status)
                                }
                            }
                        }
                        http.send(params);
                    }
                }

                Action {
                    objectName: "comments"

                    text: "comments"
                    iconSource: Qt.resolvedUrl("comments.png")


                    onTriggered: {
                        mainPageStack.push(commentpage)
                        console.log("item clicked")
                        commentslistmodel.source = ""
                        commentpage.permalink = linkpage.permalink
                        commentpage.title = linkpage.title
                        commentpage.likes = linkpage.likes
                        commentpage.thingname = linkpage.thingname
                        commentslistmodel.source = "http://www.reddit.com" + commentpage.permalink + ".json"
                    }
                }

                back {
                    text: "Back"
                    onTriggered: {
                        webview.url = "about:blank"
                    }
                }
            }

            property string likes: null
            property string permalink: ""
            property string thingname: ""
            property string urlviewing: "about:blank"

            Item {
                anchors.fill: parent
                WebView {
                    id: webview
                    anchors.fill: parent
                    url: linkpage.urlviewing
                    smooth: true

                    onLoadingChanged: {
                        loadProgressBar.visible = loading
                    }

                    onLoadProgressChanged: {
                        loadProgressBar.value = loadProgress
                    }
                }
            }
            ProgressBar {
                id: loadProgressBar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                minimumValue: 0
                maximumValue: 100
            }

            onUrlviewingChanged: webview.url = urlviewing
        }
        Page {
            id: settingspage
            title: "Settings"
            visible: false

            tools: ToolbarActions {
                id: settingstoolbar
                active: true
                lock: true

                Action {
                    objectName: "main"

                    text: "main"
                    iconSource: Qt.resolvedUrl("settings.png")

                    onTriggered: {
                        settingspage.loadMain()
                    }
                }

                Action {
                    objectName: "account"

                    text: "account"
                    iconSource: Qt.resolvedUrl("avatar.png")

                    onTriggered: {
                        settingspage.loadLogin()
                    }
                }

                Action {
                    objectName: "subreddits"

                    text: "subreddits"
                    iconSource: Qt.resolvedUrl("reddit.png")

                    onTriggered: {
                        settingspage.loadSubreddits()
                    }
                }
            }
            function loadMain () {
                mainsettings.visible = true
                accountsettings.visible = false
                subredditsettings.visible = false
            }
            function loadLogin () {
                mainsettings.visible = false
                accountsettings.visible = true
                subredditsettings.visible = false
            }

            function loadSubreddits () {
                mainsettings.visible = false
                accountsettings.visible = false
                subredditsettings.visible = true
            }

            Rectangle {
                id: mainsettings
                anchors.fill: parent
                color: Js.getBackgroundColor()
                visible: true

                Column {
                    anchors.fill: parent

                    Component.onCompleted: {
                        Storage.initialize()
                        console.debug("INITIALIZED")
                        if (Storage.getSetting("initialized") !== "true") {
                            // initialize settings
                            console.debug("reset settings")
                            Storage.setSetting("initialized", "true")
                            Storage.setSetting("enablethumbnails", "true")
                            Storage.setSetting("thumbnailsonleftside", "true")
                            Storage.setSetting("rounderthumbnails", "false")
                            Storage.setSetting("gridthumbnails", "false")
                            Storage.setSetting("postheight", "0")
                            Storage.setSetting("nightmode", "false")
                            Storage.setSetting("autologin", "false")
                            Storage.setSetting("sub1", "linux")
                            Storage.setSetting("sub2", "pics")
                            Storage.setSetting("sub3", "ubuntuphone")
                            Storage.setSetting("accountname", "")
                            Storage.setSetting("password", "")
                            Storage.setSetting("autohidetoolbar", "false")
                            reloadTabs()
                        }
                        // account...
                        // subreddits...
                        enablethumbnails.loadValue()
                        thumbnailsonleftside.loadValue()
                        rounderthumbnails.loadValue()
                        gridthumbnails.loadValue()
                        postheight.selectedIndex = parseInt(Storage.getSetting("postheight"))
                        nightmode.loadValue()
                        autologin.loadValue()
                        autohidetoolbar.loadValue()
                        sub1.text = (Storage.getSetting("sub1") === null) ? "" : Storage.getSetting("sub1")
                        sub2.text = (Storage.getSetting("sub2") === null) ? "" : Storage.getSetting("sub2")
                        sub3.text = (Storage.getSetting("sub3") === null) ? "" : Storage.getSetting("sub3")
                        loginbutton.enabled = (passwordtextfield.text.toString().length > 0 && accounttextfield.text.toString().length > 0)
                    }


                    ListItem.ValueSelector {
                        id: postheight
                        text: "Relative size of posts"

                        values: Js.getPostHeightArray()

                        onSelectedIndexChanged: Storage.setSetting("postheight", selectedIndex)
                    }

                    ListItem.Standard {
                        text: "Enable thumbnails"
                        height: units.gu(5)

                        control: SettingSwitch {
                            anchors.centerIn: parent
                            id: enablethumbnails
                            name: "enablethumbnails"
                            onCheckedChanged: {
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
                                reloadTabs()
                            }
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
                                subredditpagetoolbar.lock = (!autohidetoolbar.checked)
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

            Rectangle {
                id: accountsettings
                anchors.fill: parent
                color: Js.getBackgroundColor()
                visible: false

                Column {
                    anchors.fill:parent
                    ListItem.Standard {
                        width: parent.width
                        text: "If you enter a password it will be stored in clear text.\nIf you do not, you will be prompted for the password\nwhen you click 'login'"
                        enabled: true
                    }
                    ListItem.Empty {
                        width: parent.width
                        height: accounttextfield.height
                        TextField {
                            id: accounttextfield

                            width: parent.width
                            height: units.gu(8)

                            placeholderText: "username"
                            text: (Storage.getSetting("accountname") !== null) ? Storage.getSetting("accountname") : null

                            onTextChanged: {
                                loginbutton.enabled = (passwordtextfield.text.toString().length > 0 && accounttextfield.text.toString().length > 0)
                                Storage.setSetting("accountname", text)
                            }

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

                            onTextChanged: {
                                loginbutton.enabled = (passwordtextfield.text.toString().length > 0 && accounttextfield.text.toString().length > 0)
                                Storage.setSetting("password", text)
                            }

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
                                            subredditpagetoolbar.children[6].text = "logout"
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
                id: subredditsettings
                anchors.fill: parent
                color: Js.getBackgroundColor()
                visible: false

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
                                    subredditpage.tools.children[0].iconSource = Qt.resolvedUrl(subredditpage.chooseIcon(subredditColumn.stripSlashes(text)))
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
                                    subredditpage.tools.children[1].iconSource = Qt.resolvedUrl(subredditpage.chooseIcon(subredditColumn.stripSlashes(text)))
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
                                    subredditpage.tools.children[2].iconSource = Qt.resolvedUrl(subredditpage.chooseIcon(subredditColumn.stripSlashes(text)))
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

    function reloadTabs() {
        console.debug("in reddit.qml reloadTabs()")
        subredditpage.refreshTab()
        listview.positionViewAtBeginning()
    }

    function login(username, password) {

        var user = Storage.getSetting("accountname")
        var pass = Storage.getSetting("password")
        if (arguments.length == 2) {
            user = username
            pass = password
            console.log(user)
            console.log(pass)
        }

        var http = new XMLHttpRequest()
        var loginurl = "https://ssl.reddit.com/api/login";
        var params = "user=" + user + "&passwd=" + pass + "&api_type=json";
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
                        dialog.showLoginFailed()
                    } else {
                        // store this user mod hash to pass to later api methods that require you to be logged in
                        Storage.setSetting("userhash", jsonresponse["json"]["data"]["modhash"])
                        console.debug("success")
                        subredditpage.tools.children[6].text = "logout"
                        reloadTabs()
                    }
                } else {
                    console.debug("error: " + http.status)
                    subredditpage.dialog.showLoginFailed()
                }
            }
        }
        http.send(params);
    }
}
