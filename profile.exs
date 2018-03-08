binary = File.read!("160k.txt.lzf")
:fprof.trace(:start)
{time, _} = :timer.tc(fn -> Lzf.decompress(binary) end)
:fprof.trace(:stop)
:fprof.profile()
:fprof.analyse(dest: 'fprof.own.analysis', sort: :own, totals: true, cols: 132)
:fprof.analyse(dest: 'fprof.acc.analysis', sort: :acc, totals: true, cols: 132)
IO.inspect time

