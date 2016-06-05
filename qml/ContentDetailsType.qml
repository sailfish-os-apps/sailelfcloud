import QtQuick 2.0

QtObject {
    id: contentDetails
    property string contentName
    property int    contentId
    property int    contentSize
    property string contentType // vault, cluster, dataitem
    property int    contentParentId
    property string contentOwnerFirstName
    property string contentOwnerLastName
}
