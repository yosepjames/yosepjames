# Remotes

Remote instances are created at runtime by `ServerScriptService/RemoteSetup.server.lua`.

| Name               | Type        | Direction         | Payload                         |
|--------------------|-------------|-------------------|---------------------------------|
| StateChanged        | RemoteEvent | Server → Client   | newState: string                |
| TimerUpdate         | RemoteEvent | Server → Client   | secondsLeft: number             |
| PlayerDataUpdate    | RemoteEvent | Server → Client   | data: { coins: number }         |
| NotifyPlayer        | RemoteEvent | Server → Client   | message: string                 |
| RequestPlayerData   | RemoteFunction | Client → Server | (none) → data: table           |
