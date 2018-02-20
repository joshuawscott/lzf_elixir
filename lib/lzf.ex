defmodule Lzf do
  @moduledoc """
  Decompresses a binary that was compressed in LZF format.
  """

  @doc """
  Returns a decompressed binary
  """
  @spec decompress(binary) :: binary
  def decompress(compressed) do
    chunks = []
    parse_chunks(compressed, chunks)
  end

  # parse_chunks reads a chunk off then decompresses it with a helper, and adds the decompressed
  # chunk to a list. The list is finally reveresed and converted to binary.
  @spec parse_chunks(binary, iodata) :: binary
  def parse_chunks("", chunks) do
    decompressed =
      chunks
      |> :lists.reverse()
      |> IO.iodata_to_binary()

    decompressed
  end

  # Start of a chunk
  def parse_chunks(<<"ZV", rest::binary>>, chunks) do
    parse_chunks(rest, chunks)
  end

  # Uncompressed Chunk
  def parse_chunks(
        <<0::size(8), chunk_length::size(16), chunk::binary-size(chunk_length), rest::binary()>>,
        chunks
      ) do
    parse_chunks(rest, [chunk | chunks])
  end

  # Compressed chunk
  def parse_chunks(
        <<1::size(8), chunk_length::size(16), original_length::size(16),
          compressed_chunk::binary-size(chunk_length), rest::binary>>,
        chunks
      ) do
    chunk = decompress_chunk(compressed_chunk)

    if :erlang.byte_size(chunk) != original_length do
      IO.inspect("expected #{original_length}, got #{:erlang.byte_size(chunk)}")
    end

    parse_chunks(rest, [chunk | chunks])
  end

  def decompress_chunk(chunk) do
    decompress_chunk(chunk, 0, "")
  end

  # Literal run
  def decompress_chunk(
        <<segment_code::integer-size(8), rest::binary>>,
        position,
        decompressed
      )
      when segment_code < 0x20 do
    size = segment_code + 1
    <<run::binary-size(size), rest::binary>> = rest
    decompress_chunk(rest, position + size, decompressed <> run)
  end

  # Short backreference
  def decompress_chunk(
        <<run_length_code::size(3), offset_code::size(13), rest::binary>>,
        position,
        decompressed
      )
      when run_length_code >= 1 and run_length_code <= 6 do
    run_length = run_length_code + 2
    offset = offset_code + 1
    copied = copy_backreference(decompressed, offset, run_length)
    bytes_copied = :erlang.byte_size(copied)
    decompress_chunk(rest, position + bytes_copied, decompressed <> copied)
  end

  # Long backreference
  def decompress_chunk(
        <<7::size(3), high_offset_code::size(5), run_length_code::size(8),
          low_offset_code::size(8), rest::binary>>,
        position,
        decompressed
      ) do
    <<offset_code::size(16)>> = <<0::size(3), high_offset_code::size(5), low_offset_code>>
    run_length = run_length_code + 9
    offset = offset_code + 1
    copied = copy_backreference(decompressed, offset, run_length)
    bytes_copied = :erlang.byte_size(copied)
    decompress_chunk(rest, position + bytes_copied, decompressed <> copied)
  end

  def decompress_chunk("", _, decompressed) do
    decompressed
  end

  defp copy_backreference(decompressed, offset, run_length) do
    len = :erlang.byte_size(decompressed)
    start = len - offset

    case decompressed do
      <<_::binary-size(start), copied::binary-size(run_length), _::binary()>> ->
        copied

      <<_::binary-size(start), rest::binary()>> ->
        size = :erlang.byte_size(rest)
        copies = div(run_length, size)
        remainder = rem(run_length, size)
        extra = :binary.part(rest, {0, remainder})
        String.duplicate(rest, copies) <> extra
    end
  end
end
