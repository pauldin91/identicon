defmodule Identicon do
  import Mogrify

  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> draw_image
    |> save_image(input)
  end

  def save_image(image, input) do
    folder = "generated"
    File.mkdir_p(folder)
    File.write!("#{folder}/#{input}.png", image)
  end

  def draw_image(%Identicon.Image{color: {r, g, b}, grid: grid}) do
    path = "temporary.png"
    size = "250x250"
    color = "rgb(#{r},#{g},#{b})"

    %Mogrify.Image{}
    |> custom("size", size)
    |> canvas("white")
    |> create(path: path)
    |> save()

    image =
      Mogrify.open(path)
      |> custom("fill", color)
      |> custom("stroke", "none")

    Enum.each(grid, fn {{x1, y1}, {x2, y2}} ->
      image
      |> custom("draw", "rectangle #{x1},#{y1} #{x2},#{y2}")
      |> save(in_place: true)
    end)

    File.read!(path)
  end

  def fill_rectangle({{sh, sv}, {th, tv}}, {r, g, b}) do
    for x <- sh..(th - 1), y <- sv..(tv - 1), do: {x, y, r, g, b}
  end

  def build_grid(%Identicon.Image{hex: hex} = image, size \\ 3) do
    %Identicon.Image{
      image
      | grid:
          hex
          |> Stream.chunk_every(size)
          |> Stream.take_while(fn list -> length(list) == size end)
          |> Enum.map(fn list -> list ++ tl(Enum.reverse(list)) end)
          |> List.flatten()
          |> Stream.with_index()
          |> Stream.filter(fn {num, _} -> rem(num, 2) == 0 end)
          |> Enum.map(fn {_, index} ->
            h = rem(index, 5) * 50
            v = div(index, 5) * 50
            {{h, v}, {h + 50, v + 50}}
          end)
    }
  end

  def pick_color(%Identicon.Image{hex: [r, g, b | _]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end
end
