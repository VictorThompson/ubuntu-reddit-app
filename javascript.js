function getBackgroundColor () {
    if (Storage.getSetting("nightmode") == "true")
        return "#333333"
    else
        return "#eeeeee"
}

function getDimmedBackgroundColor () {
    if (Storage.getSetting("nightmode") == "true")
        return "#444444"
    else
        return "#dddddd"
}

function getFetchedArray () {
    return ["25", "50", "100", "200"]
}

function getPostHeightArray () {
    return ["6", "7", "8", "9"]
}

function getFlipSpeed() {
    return 300
}
