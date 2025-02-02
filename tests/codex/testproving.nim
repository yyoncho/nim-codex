import pkg/asynctest
import pkg/chronos
import pkg/codex/proving
import ./helpers/mockproofs
import ./helpers/mockclock
import ./examples

suite "Proving":

  var proving: Proving
  var proofs: MockProofs
  var clock: MockClock

  setup:
    proofs = MockProofs.new()
    clock = MockClock.new()
    proving = Proving.new(proofs, clock)
    await proving.start()

  teardown:
    await proving.stop()

  proc advanceToNextPeriod(proofs: MockProofs) {.async.} =
    let periodicity = await proofs.periodicity()
    clock.advance(periodicity.seconds.truncate(int64))
    await sleepAsync(2.seconds)

  test "maintains a list of contract ids to watch":
    let id1, id2 = ContractId.example
    check proving.contracts.len == 0
    proving.add(id1)
    check proving.contracts.contains(id1)
    proving.add(id2)
    check proving.contracts.contains(id1)
    check proving.contracts.contains(id2)

  test "removes duplicate contract ids":
    let id = ContractId.example
    proving.add(id)
    proving.add(id)
    check proving.contracts.len == 1

  test "invokes callback when proof is required":
    let id = ContractId.example
    proving.add(id)
    var called: bool
    proc onProofRequired(id: ContractId) =
      called = true
    proving.onProofRequired = onProofRequired
    proofs.setProofRequired(id, true)
    await proofs.advanceToNextPeriod()
    check called

  test "callback receives id of contract for which proof is required":
    let id1, id2 = ContractId.example
    proving.add(id1)
    proving.add(id2)
    var callbackIds: seq[ContractId]
    proc onProofRequired(id: ContractId) =
      callbackIds.add(id)
    proving.onProofRequired = onProofRequired
    proofs.setProofRequired(id1, true)
    await proofs.advanceToNextPeriod()
    check callbackIds == @[id1]
    proofs.setProofRequired(id1, false)
    proofs.setProofRequired(id2, true)
    await proofs.advanceToNextPeriod()
    check callbackIds == @[id1, id2]

  test "invokes callback when proof is about to be required":
    let id = ContractId.example
    proving.add(id)
    var called: bool
    proc onProofRequired(id: ContractId) =
      called = true
    proving.onProofRequired = onProofRequired
    proofs.setProofRequired(id, false)
    proofs.setProofToBeRequired(id, true)
    await proofs.advanceToNextPeriod()
    check called

  test "stops watching when contract has ended":
    let id = ContractId.example
    proving.add(id)
    proofs.setProofEnd(id, clock.now().u256)
    await proofs.advanceToNextPeriod()
    var called: bool
    proc onProofRequired(id: ContractId) =
      called = true
    proving.onProofRequired = onProofRequired
    proofs.setProofRequired(id, true)
    await proofs.advanceToNextPeriod()
    check not called

  test "submits proofs":
    let id = ContractId.example
    let proof = seq[byte].example
    await proving.submitProof(id, proof)

  test "supports proof submission subscriptions":
    let id = ContractId.example
    let proof = seq[byte].example

    var receivedIds: seq[ContractId]
    var receivedProofs: seq[seq[byte]]

    proc onProofSubmission(id: ContractId, proof: seq[byte]) =
      receivedIds.add(id)
      receivedProofs.add(proof)

    let subscription = await proving.subscribeProofSubmission(onProofSubmission)

    await proving.submitProof(id, proof)

    check receivedIds == @[id]
    check receivedProofs == @[proof]

    await subscription.unsubscribe()
