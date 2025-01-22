defmodule TreeTraversal do
  @scale 30

  def depth_first(tree, level, left_lim, root_x \\ nil, right_lim \\ nil) do
    case tree do
      %{left: nil, right: nil, val: val} ->
        {val, root_x, right_lim, left_lim}

      %{left: left, right: nil, val: val} ->
        depth_first(left, level + 1, left_lim, root_x, right_lim)

      %{left: nil, right: right, val: val} ->
        depth_first(right, level + 1, left_lim, root_x, right_lim)

      %{left: left, right: right, val: val} ->
        {l_root_x, l_right_lim} = depth_first(left, level + 1, left_lim, nil, nil)
        {r_root_x, r_left_lim} = depth_first(right, level + 1, nil, nil, nil)

        r_left_lim = l_right_lim + @scale
        root_x = div(l_root_x + r_root_x, 2)

        {val, root_x, right_lim, left_lim}
    end
  end
end

defmodule Main do
  def run do
    # Create the tree
    tree = %{
      id: "a", val: 10,
      left: %{
        id: "b", val: 5,
        left: nil, right: nil,
        x: 0.0, y: 0.0
      },
      right: %{
        id: "c", val: 15,
        left: nil,
        right: %{
          id: "d", val: 20,
          left: %{
            id: "e", val: 18,
            left: %{
              id: "g", val: 17,
              left: nil, right: nil,
              x: 0.0, y: 0.0
            },
            right: %{
              id: "h", val: 19,
              left: nil, right: nil,
              x: 0.0, y: 0.0
            },
            x: 0.0, y: 0.0
          },
          right: %{
            id: "f", val: 25,
            left: nil, right: nil,
            x: 0.0, y: 0.0
          },
          x: 0.0, y: 0.0
        },
        x: 0.0, y: 0.0
      },
      x: 0.0, y: 0.0
    }

    # Call the depth_first function
    result = TreeTraversal.depth_first(tree, 0, nil)
    IO.inspect(result)
  end
end

# To run the main function
Main.run()
