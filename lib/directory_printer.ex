defmodule DirectoryPrinter do
  @spec print_directory_structure(String.t(), String.t(), integer, [String.t()]) :: :ok
  def print_directory_structure(directory, prefix, max_level, skip_dirs \\ ["deps"])
      when is_integer(max_level) and max_level >= 0 do
    items = File.ls!(directory)
    total_items = length(items)

    Enum.each(items, fn item ->
      total_items = total_items - 1

      # Create the full path
      full_path = Path.join([directory, item])

      if File.dir?(full_path) do
        if Enum.member?(skip_dirs, item) do
          IO.puts("Skipping directory: #{item}")
        else
          IO.puts("#{prefix}├── Directory: #{item}")
          new_prefix = if total_items > 0, do: "#{prefix}│  ", else: "#{prefix}   "
          print_directory_structure(full_path, new_prefix, max_level - 1, skip_dirs)
        end
      else
        IO.puts("#{prefix}├── File: #{item}")
      end
    end)

    :ok
  end

  def print_directory_structure(_directory, _prefix, _max_level, _skip_dirs) do
  end

  @spec print_cwd_and_deeper_levels(integer) :: :ok
  def print_cwd_and_deeper_levels(max_level) do
    cwd = File.cwd!()
    IO.puts("Current working directory: #{cwd}")
    IO.puts("Root:")
    print_directory_structure(cwd, "", max_level)
    :ok
  end
end
