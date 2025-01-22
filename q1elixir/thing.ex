defmodule TreeTraversal do
  @scale 30

  def depth_first(tree, level, left_lim, root_x \\ nil, right_lim \\ nil) do
    case tree do
      {:tree, x, y, :leaf, :leaf} ->
        {x, root_x, right_lim, left_lim}
        y = @scale * level

      {:tree, x, y, left, :leaf} ->
        {x, root_x}
        y = @scale * level
        depth_first(left, level + 1, left_lim, root_x, right_lim)

      {:tree, x, y, :leaf, right} ->
        {x, root_x}
        y = @scale * level
        depth_first(right, level + 1, left_lim, root_x, right_lim)

      {:tree, x, y, left, right} ->
        {l_root_x, l_right_lim, r_root_x, r_left_lim} =
          depth_first(left, level + 1, left_lim, nil, nil) ++
          depth_first(right, level + 1, nil, nil, nil)

        y = @scale * level
        r_left_lim = l_right_lim + @scale
        root_x = div(l_root_x + r_root_x, 2)

        {x, root_x, right_lim, left_lim}
    end
  end
end
