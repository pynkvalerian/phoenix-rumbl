import Player from "./player"

let Video = {
  init(socket, element){
    if(!element){ return }
    let playerId = element.getAttribute("data-player-id")
    let videoId = element.getAttribute("data-id")
    socket.connect()
    // player initialized with playerId
    Player.init(element.id, playerId, () => {
      // run callback with videoId and socket
      this.onReady(videoId, socket)
    })
  },

  onReady(videoId, socket){
    let msgContainer = document.getElementById("msg-container")
    let msgInput = document.getElementById("msg-input")
    let postButton = document.getElementById("msg-submit")
    // connect to phoenix videoChannel
    // give it a topic: videos:<videoId>
    let vidChannel = socket.channel("videos:" + videoId)
    // TODO join vidchannel
    vidChannel.join()
      .receive("ok", resp =>
        console.log("joined the video channel", resp)
      )
      .receive("error", reason =>
        console.log("join failed", reason)
      )
  }
}

export default Video