function getBackgroundColor () {
    if (Storage.getSetting("nightmode") == "true")
        return "#333333"
    else
        return "#eeeeee"
}

function getFetchedArray () {
    return ["10", "15", "25", "50"]
}

function getPostHeightArray () {
    return ["6", "8", "10", "12"]
}

function getFlipSpeed() {
    return 300
}
