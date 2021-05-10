import libp2p
import pkg/stint
import pkg/questionable
import pkg/questionable/results
import pkg/upraises
import ./bitswap

export questionable
export stint
export BlockPresenceType

upraises.push: {.upraises: [].}

type
  PresenceMessage* = bitswap.BlockPresence
  Presence* = object
    cid*: Cid
    have*: bool
    price*: UInt256

func init*(_: type PresenceMessage, presence: Presence): PresenceMessage =
  PresenceMessage(
    cid: presence.cid.data.buffer,
    `type`: if presence.have: presenceHave else: presenceDontHave,
    price: @(presence.price.toBytesBE)
  )

func parse(_: type UInt256, bytes: seq[byte]): ?UInt256 =
  if bytes.len > 32:
    return UInt256.none
  UInt256.fromBytesBE(bytes).some

func init*(_: type Presence, message: PresenceMessage): ?Presence =
  without cid =? Cid.init(message.cid) and
          price =? UInt256.parse(message.price):
    return none Presence

  some Presence(
    cid: cid,
    have: message.`type` == presenceHave,
    price: price
  )
