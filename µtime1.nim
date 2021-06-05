import std/monotimes
import std/os
import std/osproc
import std/posix
import std/strutils
import std/times

proc error(errnum: cint; message: varargs[string]) =
  stderr.write getAppFilename(), ": "
  stderr.write message
  if errnum != 0:
    stderr.write ": ", strerror(errnum)
  stderr.write '\n'
  stderr.flushFile

proc run_command(cmd: seq[string]) =
  let args = cmd[1 .. ^1]
  let start = getMonoTime()
  let child = startProcess(cmd[0], args=args, options={poUsePath, poParentStreams})
  discard child.waitForExit
  let stop = getMonoTime()
  child.close

  var res: Rusage
  if getrusage(RUSAGE_CHILDREN, addr res) == -1:
    error errno, "error getting resource usage"
    quit -1

  let utime = res.ru_utime
  let stime = res.ru_stime
  stderr.write "User: ", utime.tv_sec.clong, ".", align($utime.tv_usec, 6, '0'), "s, "
  stderr.write "Sys: ", stime.tv_sec.clong, ".", align($stime.tv_usec, 6, '0'), "s, "
  let wtime = stop - start
  let microPart = wtime.inMicroseconds - 1_000_000 * wtime.inSeconds
  stderr.write "Elapsed: ", wtime.inSeconds, ".", align($microPart, 6, '0'), "s, "
  stderr.write "MaxRss: ", res.ru_maxrss, "kb\n"

run_command commandLineParams()
