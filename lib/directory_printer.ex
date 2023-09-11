defmodule DirectoryPrinter do
  @spec print_directory_structure(String.t(), integer, integer) :: :ok
  def print_directory_structure(directory, current_level, max_level)
      when current_level <= max_level do
    # Indent for visual hierarchy
    indent = String.duplicate("  ", current_level)

    # List items in the current directory
    items = File.ls!(directory)

    # Print each item
    Enum.each(items, fn item ->
      # Create the full path
      full_path = Path.join([directory, item])

      # Check if the item is a directory
      if File.dir?(full_path) do
        IO.puts("#{indent}Directory: #{item}")
        print_directory_structure(full_path, current_level + 1, max_level)
      else
        IO.puts("#{indent}File: #{item}")
      end
    end)

    :ok
  end

  def print_directory_structure(_directory, _current_level, _max_level),
    do: IO.puts("Max level reached")

  @spec print_cwd_and_deeper_levels(integer) :: :ok
  def print_cwd_and_deeper_levels(max_level) do
    cwd = File.cwd!()
    IO.puts("Current working directory: #{cwd}")
    print_directory_structure(cwd, 0, max_level)
    :ok
  end
end
