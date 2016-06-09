.pragma library

WorkerScript.onMessage = function(message) {

    for (var i = 0; i < message.localPaths; i++)
        WorkerScript.sendMessage({"parentId":message.parentId,
                                  "localPath":message.localPaths[i],
                                  "remoteName":message.remoteNames[i]});
}
