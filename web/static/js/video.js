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

    // when submit button is clicked
    postButton.addEventListener("click", e => {
      let payload = {
        body: msgInput.value,
        at: Player.getCurrentTime()
      }
      // push payload (msg input) to server
      vidChannel.push("new_annotation", payload)
        .receive("error", e => console.log(e))
      msgInput.value = ""
    })

    // receive message
    // vidChannel.on("ping", ({count}) => console.log("PING", count))

    vidChannel.on("new_annotation", (resp) => {
      this.renderAnnotation(msgContainer, resp)
    })

    // join vidchannel
    vidChannel.join()
      .receive("ok", ({annotations}) =>
        // console.log("HERE", annotations)
        annotations.forEach(
          ann => this.renderAnnotation(msgContainer, ann)
        )
      )
      .receive("error", reason =>
        console.log("join failed", reason)
      )
  },

  // safely escape user input (prevent XSS attacks)
  esc(str){
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },

  // append new msg into msgContainer
  renderAnnotation(msgContainer, {user, body, at}){
    let template = document.createElement("div")
    template.innerHTML = `
      <a href="#" data-seek="${this.esc(at)}">
        <b>${this.esc(user.username)}</b>: ${this.esc(body)}
      </a>
    `
    msgContainer.appendChild(template)
    msgContainer.scrollTop = msgContainer.scrollHeight
  }
}

export default Video