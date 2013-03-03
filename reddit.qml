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
    width: units.gu(50)
    height: units.gu(75)

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

                                text: "could not login check\nsettings"
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
                                    if (subreddittextfield.text !== "") {
                                        var split = subreddittextfield.text.split("/")
                                        var i = 0
                                        for (; split.length; i++) {
                                            if ( split[i] !== "" && split[i] !== "r") break
                                        }
                                        subreddittab.url = "/r/" + split[i]
                                    } else {
                                        subreddittab.url = "/"
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
                    if (toolbar.sub1action.text === "" || toolbar.sub1action.text === "Unknown") {
                        toolbar.sub1action.text = "ubuntu"
                    }
                    if (toolbar.sub2action.text === "" || toolbar.sub2action.text === "Unknown") {
                        toolbar.sub2action.text = "pics"
                    }
                    if (toolbar.sub3action.text === "" || toolbar.sub3action.text === "Unknown") {
                        toolbar.sub3action.text = "linux"
                    }
                    if (toolbar.sub4action.text === "" || toolbar.sub4action.text === "Unknown") {
                        toolbar.sub4action.text = "ubuntuphone"
                    }
                }

                tools: ToolbarActions {
                    id: toolbar
                    function chooseIcon (text) {
                        var test = text.toLowerCase().toString()
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

                        text: (Storage.getSetting("sub1").toString().length > 0) ? Storage.getSetting("sub1").toString() : "Unknown"
                        iconSource: toolbar.chooseIcon(text)
                        visible: (Storage.getSetting("sub1").toString().length > 0) ? true : false

                        onTriggered: {
                            subreddittab.url = "/r/" + Storage.getSetting("sub1").toString()
                            reloadTabs()
                        }
                    }
                    Action {
                        objectName: "sub2action"

                        text: (Storage.getSetting("sub2").toString().length > 0) ? Storage.getSetting("sub2").toString() : "Unknown"
                        iconSource: toolbar.chooseIcon(text)

                        onTriggered: {
                            subreddittab.url = "/r/" + Storage.getSetting("sub2").toString()
                            reloadTabs()
                        }
                    }
                    Action {
                        objectName: "sub3action"

                        text: (Storage.getSetting("sub3").toString().length > 0) ? Storage.getSetting("sub3").toString() : "Unknown"
                        iconSource: toolbar.chooseIcon(text)

                        onTriggered: {
                            subreddittab.url = "/r/" + Storage.getSetting("sub3").toString()
                            reloadTabs()
                        }
                    }
                    Action {
                        objectName: "sub4action"

                        text: (Storage.getSetting("sub4").toString().length > 0) ? Storage.getSetting("sub4").toString() : "Unknown"
                        iconSource: toolbar.chooseIcon(text)

                        onTriggered: {
                            subreddittab.url = "/r/" + Storage.getSetting("sub4").toString()
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
                            subreddittab.url = "/"
                            reloadTabs()
                        }
                    }

                    Action {
                        objectName: "action"

                        text: "login"
                        iconSource: Qt.resolvedUrl("avatar.png")

                        onTriggered: {
                            login()
                        }
                    }
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
                    NumberAnimation { target: linkrotation; property: "angle"; duration: (Storage.getSetting("flippages") != "true")? 0 : flipspeed }
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

                    ListView {
                        id: listview
                        anchors.fill: parent

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
                                            false
                                        } else {
                                            flipablelink.flipped = true
                                            backsidelink.commentpage = false
                                            webview.url = model.data.url
                                        }
                                    }
                                    enabled: !flipablelink.flipped
                                }
                            }

                            Rectangle {
                                id: itemrectangle
                                height: parent.height
                                width: parent.width - thumbshape.width

                                anchors.left: (Storage.getSetting("thumbnailsonleftside") == "true") ? undefined : parent.left
                                anchors.right: (Storage.getSetting("thumbnailsonleftside") == "true") ? parent.right : undefined

                                color: Js.getBackgroundColor()

                                Flipable {
                                    id: itemflipable
                                    anchors.fill: parent

                                    property bool flipped: false

                                    front: Rectangle {
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
                                            onClicked: itemflipable.flip()
                                        }
                                    }

                                    back: Rectangle {
                                        id: backsideitem
                                        anchors.fill: parent

                                        Row {
                                            anchors.fill: parent

                                            Rectangle {
                                                width: parent.width / 5
                                                height: parent.height
                                                color: Js.getBackgroundColor()
                                                Rectangle {
                                                    width: parent.width
                                                    height: parent.height / 2
                                                    color: Js.getBackgroundColor()
                                                    anchors.top: parent.top

                                                    Rectangle {
                                                        height: (parent.width < parent.height) ? parent.width : parent.height
                                                        width: parent.width
                                                        color: Js.getBackgroundColor()

                                                        anchors.left: parent.left
                                                        anchors.top: parent.top

                                                        Image {
                                                            id: upvote
                                                            anchors.centerIn: parent
                                                            source: (model.data.likes === true) ? "upvote.png" : "upvoteEmpty.png"
                                                            fillMode: Image.Top
                                                        }

                                                    }

                                                    MouseArea {
                                                        anchors.fill:parent
                                                        enabled: itemflipable.flipped
                                                        onClicked: {
                                                            var http = new XMLHttpRequest()
                                                            var voteurl = "http://www.reddit.com/api/vote"
                                                            var direction = (upvote.source.toString().match(".*upvote.png$")) ? "0" : "1"
                                                            var params = "dir=" + direction + "&id="+model.data.name+"&uh="+Storage.getSetting("userhash")+"&api_type=json";
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
                                                                            upvote.source = (upvote.source.toString().match(".*upvote.png$")) ? "upvoteEmpty.png" : "upvote.png"
                                                                            downvote.source = "downvoteEmpty.png"
                                                                        }
                                                                    } else {
                                                                        console.debug("error: " + http.status)
                                                                    }
                                                                }
                                                            }
                                                            http.send(params);
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    width: parent.width
                                                    height: parent.height / 2
                                                    anchors.bottom: parent.bottom

                                                    color: Js.getBackgroundColor()

                                                    Rectangle {
                                                        height: (parent.width < parent.height) ? parent.width : parent.height //smallest of width and height
                                                        width: parent.width
                                                        color: Js.getBackgroundColor()

                                                        anchors.left: parent.left
                                                        anchors.bottom: parent.bottom

                                                        Image {
                                                            id: downvote
                                                            source: (model.data.likes === false) ?  "downvote.png" : "downvoteEmpty.png"
                                                            fillMode: Image.Center
                                                            anchors.centerIn: parent
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        enabled: itemflipable.flipped
                                                        onClicked: {
                                                            var http = new XMLHttpRequest()
                                                            var direction = (downvote.source.toString().match(".*downvote.png$")) ? "0" : "-1"
                                                            var voteurl = "http://www.reddit.com/api/vote"
                                                            var params = "dir=" + direction + "&id="+model.data.name+"&uh="+Storage.getSetting("userhash")+"&api_type=json";
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
                                                                            downvote.source = (downvote.source.toString().match(".*downvote.png$")) ? "downvoteEmpty.png" : "downvote.png"
                                                                            upvote.source = "upvoteEmpty.png"
                                                                        }
                                                                    } else {
                                                                        console.debug("error: " + http.status)
                                                                    }
                                                                }
                                                            }
                                                            http.send(params);
                                                        }
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                id: backid
                                                width: 2 * parent.width / 5
                                                height: parent.height
                                                color: Js.getBackgroundColor()

                                                Label {
                                                    anchors.centerIn: parent
                                                    text: "back"
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    enabled: itemflipable.flipped
                                                    onClicked: itemflipable.flip()
                                                }
                                            }

                                            Rectangle {
                                                width: 2 * parent.width / 5
                                                height: parent.height
                                                color: Js.getBackgroundColor()

                                                Label {
                                                    anchors.centerIn: parent
                                                    text: "comments"
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    enabled: itemflipable.flipped
                                                    onClicked: {
                                                        flipablelink.flip()
                                                        commentrectangle.loadPage(model.data.permalink)
                                                        backsidelink.commentpage = true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    transform: Rotation {
                                        id: rotation
                                        origin.x: itemflipable.width / 3
                                        origin.y: itemflipable.height / 2
                                        axis.x: 1; axis.y: 0; axis.z: 0     // add option: which axis
                                        angle: 0    // the default angle
                                    }

                                    states: State {
                                        name: "back"
                                        PropertyChanges { target: rotation; angle: 180 }
                                        when: itemflipable.flipped
                                    }

                                    transitions: Transition {
                                        NumberAnimation { target: rotation; property: "angle"; duration: (Storage.getSetting("flippages") != "true")? 0 : 200 }
                                    }

                                    function flip () {
                                        itemflipable.flipped = !itemflipable.flipped
                                    }
                                }
                            }
                        }
                    }
                }

                back: Rectangle {
                    id: backsidelink

                    property bool commentpage: false
                    property string urlviewing: ""

                    anchors.fill: parent
                    color: Js.getBackgroundColor()
                    enabled: flipablelink.flipped

                    Button {
                        id: linkbackbutton
                        text: "Go back"
                        height: units.gu(4)
                        width: parent.width
                        onClicked: {
                            flipablelink.flip()
                            webview.url = "about:blank"
                        }
                    }

                    Rectangle {
                        id: commentrectangle
                        opacity: (backsidelink.commentpage)? 1 : 0
                        color: Js.getBackgroundColor()

                        // why isn't this enabled?
                        // TODO: fix contents

                        height: parent.height - linkbackbutton.height
                        width: parent.width
                        anchors.top: linkbackbutton.bottom

                        property string permalink: ""

                        function loadPage (n_permalink) {
                            permalink = n_permalink;
                            commentslistmodel.source = "http://www.reddit.com" + permalink + ".json"
                            pagestack.clear()
                            pagestack.push(rootpage)
                        }

                        JSONListModel {
                            id: commentslistmodel
                            query: "$[1].data.children[*]"
                        }


                        PageStack {
                            id: pagestack
                            anchors.fill: parent

                            // try to merge these next 2
                            Component {
                                id: rootpage
                                Page {
                                    title: ""

                                    ListView {
                                        anchors.fill: parent
                                        model: commentslistmodel.model

                                        delegate: ListItem.Standard {
                                            text: model.data.body

                                            progression: true
                                            onClicked: {
                                                console.debug("clicked")
                                                pagestack.push(newpage, {commentsModel: model.data.replies.data.children})
                                            }
                                        }
                                    }
                                }
                            }

//                            Component {
//                                id: newpage

//                                Page {
//                                    id: page
//                                    title: ""

//                                    property variant commentsModel: []

//                                    ListView {
//                                        anchors.fill: parent
//                                        model: commentsModel

//                                        delegate: ListItem.Standard {
//                                            text: modelData.data.body


//                                            progression: true
//                                            onClicked: pagestack.push(newpage, {commentsModel: modelData.data.replies.data.children})
//                                        }
//                                    }
//                                }
//                            }
                        }
                    }

                    Rectangle {
                        id: linkrectangle
                        opacity: (backsidelink.commentpage)? 0 : 1

                        height: parent.height - linkbackbutton.height
                        width: parent.width
                        anchors.top: linkbackbutton.bottom

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
                                Storage.setSetting("postheight", "0")
                                Storage.setSetting("nightmode", "false")
                                Storage.setSetting("flippages", "true")
                                Storage.setSetting("autologin", "false")
                                Storage.setSetting("sub1", "ubuntu")
                                Storage.setSetting("sub2", "pics")
                                Storage.setSetting("sub3", "linux")
                                Storage.setSetting("sub4", "ubuntuphone")
                                Storage.setSetting("accountname", "")
                                Storage.setSetting("password", "")
                                reloadTabs()
                            }
                            numberfetchedposts.selectedIndex = parseInt(Storage.getSetting("numberfetchedposts"))
                            numberfetchedcomments.selectedIndex = parseInt(Storage.getSetting("numberfetchedcomments"))
                            // account...
                            // subreddits...
                            enablethumbnails.loadValue()
                            thumbnailsonleftside.loadValue()
                            rounderthumbnails.loadValue()
                            postheight.selectedIndex = parseInt(Storage.getSetting("postheight"))
                            nightmode.loadValue()
                            flippages.loadValue()
                            autologin.loadValue()
                            sub1.text = Storage.getSetting("sub1")
                            sub2.text = Storage.getSetting("sub2")
                            sub3.text = Storage.getSetting("sub3")
                            sub4.text = Storage.getSetting("sub4")
                        }

                        ListItem.SingleControl {
                            control: Button {
                                height: units.gu(4)
                                width: parent.width * 3 / 4
                                anchors.topMargin: units.gu(1)
                                anchors.bottomMargin: units.gu(1)
                                anchors.centerIn: parent

                                text: "Account..."

                                onClicked: backside.loadLogin()
                            }
                        }

                        ListItem.SingleControl {
                            control: Button {
                                height: units.gu(4)
                                width: parent.width * 3 / 4
                                anchors.topMargin: units.gu(1)
                                anchors.bottomMargin: units.gu(1)

                                text: "Subreddits..."

                                onClicked: backside.loadSubreddits()
                            }
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
                            text: "Font size of posts"

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

                    Button {
                        id: backbutton
                        text: "Go back"
                        height: units.gu(4)
                        width: parent.width
                        onClicked: {
                            flipable.flip()
                        }
                    }

                    Rectangle {
                        height: parent.height - backbutton.height
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
                                        if ( split[i] !== "" && split[i] !== "r") break
                                    }
                                    return split[i]
                                }

                                ListItem.Empty {
                                    width: parent.width
                                    height: units.gu(8)

                                    TextField {
                                        id: sub1

                                        width: parent.width
                                        height: units.gu(8)

                                        text: (Storage.getSetting("sub1").toString().length) ? Storage.getSetting("sub1") : "ubuntu"

                                        onTextChanged: Storage.setSetting("sub1", subredditColumn.stripSlashes(text))

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

                                        text: (Storage.getSetting("sub2").toString().length) ? Storage.getSetting("sub2") : "funny"

                                        onTextChanged: Storage.setSetting("sub2", subredditColumn.stripSlashes(text))

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

                                        text: (Storage.getSetting("sub3").toString().length) ? Storage.getSetting("sub3") : "pics"

                                        onTextChanged: Storage.setSetting("sub3", subredditColumn.stripSlashes(text))

                                        enabled: true

                                        font.pixelSize: parent.height / 2
                                    }
                                }
                                ListItem.Empty {
                                    width: parent.width
                                    height: units.gu(8)

                                    TextField {
                                        id: sub4

                                        width: parent.width
                                        height: units.gu(8)

                                        text: (Storage.getSetting("sub4").toString().length) ? Storage.getSetting("sub4") : "gifs"

                                        onTextChanged: Storage.setSetting("sub4", subredditColumn.stripSlashes(text))


                                        enabled: true

                                        font.pixelSize: parent.height / 2
                                    }
                                }
                                ListItem.Empty {
                                    width: parent.width
                                    height: units.gu(8)

                                    Text {
                                        id: subsmessage
                                        anchors.bottom: parent.bottom
                                        anchors.centerIn: parent

                                        //width: parent.width
                                        height: units.gu(8)
                                        color: (Storage.getSetting("nightmode") == "true") ? "#FFFFFF" : "#000000"

                                        text: "Note: app will need to be restarted\nfor changes to show up on the toolbar."

                                        enabled: true
                                        opacity: .6

                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


//        SubredditTab {url: "/r/all"} // reddit.com/r/all
//        SubredditTab {url: "/r/funny"}
//        SubredditTab {url: "/r/waterporn"}

//        Tab {
//            objectName: "Tab1"
            
//            title: i18n.tr("reddit")
            
//            // Tab content begins here
//            page: Page {
//                Column {
//                    anchors.centerIn: parent
//                    Label {
//                        text: i18n.tr("Swipe from right to left to change tab.")
//                    }
//                }
//            }
//        }
    }

    function reloadTabs() {
        console.debug("in reddit.qml reloadTabs()")
        subreddittab.refreshTab()
    }

    function login() {
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
