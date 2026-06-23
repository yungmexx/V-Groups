let groupMembers = []
let groupLeaderId = null
let myServerId = null

let myName = "Unknown"
let leaderName = "Unknown"
const groupMembersEl = document.getElementById("groupMembers")
const playersListEl = document.getElementById("playersList")
const groupCountEl = document.getElementById("groupCount")


const invitePopup = document.getElementById("invitePopup")
const popupText = document.getElementById("popupText")
let currentInviteGroup = null

let currentGroupId = null

function renderGroupMembers() {
    document.querySelector(".my-avatar").innerHTML = `
          <div class="member-avatar">
                <img src="assets/group.png" alt="avatar">
            </div>
    `
    const isLeader = myServerId === groupLeaderId
    groupMembersEl.innerHTML = ""
    groupMembers.forEach(member => {
        if (!member || typeof member !== "object") return
        const isMemberLeader = member.id === groupLeaderId
        const div = document.createElement("div")
        div.className = "member-card"
        div.innerHTML = `
            <div class="member-left">
            <div class="member-avatar">
                <img src="assets/player.png" alt="avatar">
            </div>
                <div class="member-info">
                    <h3>
                        ${member.id === groupLeaderId ? leaderName : member.name}
                    </h3>
                    <span>
                        ${member.id === groupLeaderId ? `Group Leader` : "Group Member"} &nbsp;·&nbsp; ID: ${member.id}
                    </span>
                </div>
            </div>
            <div class="member-right">
                ${
                    member.id === groupLeaderId ? `<div class="leader-tag">Leader</div>` : ``
                }
                ${isLeader && !isMemberLeader ? `
                    <button class="kick-btn" data-id="${member.id}">
                        Kick
                    </button>
                ` : ``}
                ${member.id === myServerId && !member.leader ? `
                    <button class="kick-btn leave-btn" data-id="${member.id}">
                        Leave
                    </button>
                ` : ``}
            </div>
        `
        const kickBtn = div.querySelector(".kick-btn")
        const leaveBtn = div.querySelector(".leave-btn")
        if (leaveBtn) {
            leaveBtn.addEventListener("click", () => {
                fetch(`https://${GetParentResourceName()}/leaveGroup`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },

                    body: JSON.stringify({
                        playerId: member.id,
                        groupId: currentGroupId
                    })

                   // body: JSON.stringify({})
                })
            })
        }
        if (kickBtn) {
            kickBtn.addEventListener("click", () => {
                fetch(`https://${GetParentResourceName()}/kickPlayer`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        playerId: member.id,
                        groupId: currentGroupId
                    })
                })

            })

        }
        groupMembersEl.appendChild(div)
    })
    groupCountEl.innerText = `${groupMembers.length} / 4`
}

function renderNearbyPlayers(players) {
    playersListEl.innerHTML = ""
    if (!players || players.length === 0) {
        playersListEl.innerHTML = `
            <div class="player-card">
                <div class="player-info">
                    <h2>No Nearby Players</h2>
                    <span>Move closer to players</span>
                </div>
            </div>
        `
        return
    }
    players.forEach(player => {
        const div = document.createElement("div")
        div.className = "player-card"
        let status = player.status || "invite"
        let btnLabel = status.charAt(0).toUpperCase() + status.slice(1)
        let disabled = status !== "invite" ? "disabled" : ""
        div.innerHTML = `
                <div class="player-left">
                    <div class="member-avatar">
                        <img src="assets/player.png" alt="avatar">
                    </div>
                    <div class="player-info">
                        <h2>${player.name}</h2>
                        <span>ID: ${player.id} &nbsp;·&nbsp; ${player.distance}m Away</span>
                    </div>
                </div>
                <button class="invite-btn" ${disabled}>
                    ${btnLabel}
                </button>
            `


        div.querySelector(".invite-btn")
            .addEventListener("click", (e) => {

                if (player.status === "invited") return

                fetch(`https://${GetParentResourceName()}/invitePlayer`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        playerId: player.id,
                        groupId: currentGroupId
                    })
                })

            })
        playersListEl.appendChild(div)
    })
}


window.addEventListener("message", (event) => {
    const data = event.data
    if (data.action === "toggle") {
        document.querySelector(".group-ui")
            .style.display =
            data.state ? "block" : "none"
    }
    if (data.action === "setNearbyPlayers") {
        renderNearbyPlayers(data.players)
    }
})


window.addEventListener("message", (event) => {
    const data = event.data
    if (data.action === "setGroupMembers") {
        groupMembers = (data.members || []).map(m => ({
            ...m,
            leader: m.id === data.leader
        }))

        groupLeaderId = data.leader
        leaderName = data.leaderName

        currentGroupId = data.leader

        renderGroupMembers()
    }
})


document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {

        fetch(`https://${GetParentResourceName()}/close`, {
            method: "POST"
        })

        const inviteVisible = !invitePopup.classList.contains("hidden")

        if (inviteVisible && currentInviteGroup) {

            fetch(`https://${GetParentResourceName()}/declineInvite`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    groupId: currentInviteGroup
                })
            })

            invitePopup.classList.add("hidden")

            currentInviteGroup = null
        }
    }
})

document.querySelector(".group-ui")
    .style.display = "none"
renderGroupMembers()


window.addEventListener("message", (event) => {
    const data = event.data
    if (data.action === "showInvite") {
        currentInviteGroup = data.groupId
        popupText.innerText = `${data.fromName} invited you to join their group.`
        invitePopup.classList.remove("hidden")
    }

    if (data.action === "hideInvite") {
        invitePopup.classList.add("hidden")
    }

    if (data.action === "setMyId") {
        myServerId = data.id
        if (groupMembers.length > 0) {
            renderGroupMembers()
        }
    }

    if (data.action === "setMyInfo") {
        myName = data.name
        document.querySelector(".my-avatar").innerHTML = `
        <img src="assets/player.png" alt="avatar">
    `
    }

})

document.getElementById("acceptBtn")
    .addEventListener("click", () => {
        fetch(`https://${GetParentResourceName()}/acceptInvite`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                groupId: currentInviteGroup
            })
        })
        invitePopup.classList.add("hidden")
    })

document.getElementById("declineBtn")
    .addEventListener("click", () => {

        fetch(`https://${GetParentResourceName()}/declineInvite`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                groupId: currentInviteGroup
            })
        })

        invitePopup.classList.add("hidden")

    })
