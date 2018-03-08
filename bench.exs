binary = File.read!("160k.txt.lzf")
{time, _} = :timer.tc(fn -> Lzf.decompress(binary) end)
IO.inspect time

