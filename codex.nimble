mode = ScriptMode.Verbose

version = "0.1.0"
author = "Codex Team"
description = "p2p data durability engine"
license = "MIT"
binDir = "build"
srcDir = "."

requires "https://github.com/status-im/nim-libp2p-dht.git#9a872518d621bf8b390f88cd65617bca6aca1d2d"

when declared(namedBin):
  namedBin = {
    "codex/codex": "codex"
  }.toTable()

### Helper functions
proc buildBinary(name: string, srcDir = "./", params = "", lang = "c") =
  if not dirExists "build":
    mkDir "build"
  # allow something like "nim nimbus --verbosity:0 --hints:off nimbus.nims"
  var extra_params = params
  when compiles(commandLineParams):
    for param in commandLineParams:
      extra_params &= " " & param
  else:
    for i in 2..<paramCount():
      extra_params &= " " & paramStr(i)


  exec "nim " & lang & " --out:build/" & name & " " & extra_params & " " & srcDir & name & ".nim"

proc test(name: string, srcDir = "tests/", lang = "c") =
  buildBinary name, srcDir
  exec "build/" & name

task codex, "build codex binary":
  buildBinary "codex", params = "-d:chronicles_runtime_filtering -d:chronicles_log_level=TRACE"

task testCodex, "Build & run Codex tests":
  test "testCodex"

task testContracts, "Build & run Codex Contract tests":
  test "testContracts"

task testIntegration, "Run integration tests":
  codexTask()
  test "testIntegration"

task test, "Run tests":
  testCodexTask()

task testAll, "Run all tests":
  testCodexTask()
  testContractsTask()
  testIntegrationTask()
