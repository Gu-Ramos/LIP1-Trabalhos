defmodule BTreeNode do
  defstruct id: "", val: 0, right: nil, left: nil, x: 0.0, y: 0.0

  def calculate_positions(tree, level, scale, left_limit) do
    # O y do nó sempre vai ser dependente apenas do nível dele e da escala desejada.
    tree = %{tree | y: scale * level}

    case tree do
      # Caso onde o nó não tem filhos
      %{left: nil, right: nil} ->
        {%{tree | x: left_limit}, left_limit}

      # Caso onde o nó só tem o filho esquerdo
      %{left: left_child, right: nil} ->
        # calcula a posição do filho esquerdo
        {left_child, right_limit} = calculate_positions(left_child, level + 1, scale, left_limit)
        # como ele só tem um filho, a posição X dele vai ser a mesma do filho dele. (isto é, ele vai estar diretamente acima do filho dele.)
        {%{tree | left: left_child, x: left_child.x}, right_limit}

      # Caso onde o nó só tem o filho direito
      %{left: nil, right: right_child} ->
        # mesma lógica do caso acima
        {right_child, right_limit} = calculate_positions(right_child, level + 1, scale, left_limit)
        {%{tree | right: right_child, x: right_child.x}, right_limit}

      # Caso onde o nó tem os dois filhos
      %{left: left_child, right: right_child} ->
        # calcula as posições dos dois filhos
        {left_child, lchild_right_limit} = calculate_positions(left_child, level + 1, scale, left_limit)
        {right_child, rchild_right_limit} = calculate_positions(right_child, level + 1, scale, lchild_right_limit + scale)
        # o nó vai estar no meio dos dois filhos
        {%{tree | left: left_child, right: right_child, x: (left_child.x + right_child.x) / 2.0}, rchild_right_limit}
    end
  end

  def print_tree(tree, level \\ 0) do
    # nível -> id -> valor -> coordenada x -> coordenada
    IO.puts(String.duplicate("  ", level) <> "#{tree.id} (#{tree.val}) - x: #{tree.x}, y: #{tree.y}")

    if tree.left != nil do print_tree(tree.left, level + 1) end
    if tree.right != nil do print_tree(tree.right, level + 1) end
  end
end

defmodule Main do
  def main do
    # 1. cria árvore teste
    tree = %BTreeNode{
      id: "a", val: 10,
      left: %BTreeNode{
        id: "b", val: 5,
        left: nil, right: nil,
        x: 0.0, y: 0.0
      },
      right: %BTreeNode{
        id: "c", val: 15,
        left: nil,
        right: %BTreeNode{
          id: "d", val: 20,
          left: %BTreeNode{
            id: "e", val: 18,
            left: %BTreeNode{
              id: "g", val: 17,
              left: nil, right: nil,
              x: 0.0, y: 0.0
            },
            right: %BTreeNode{
              id: "h", val: 19,
              left: nil, right: nil,
              x: 0.0, y: 0.0
            },
            x: 0.0, y: 0.0
          },
          right: %BTreeNode{
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

    # 2. calcula as posições etc
    {mod_tree, _} = BTreeNode.calculate_positions(tree, 0, 30, 0)

    # 3. printa
    BTreeNode.print_tree(mod_tree, 0)

    # IO.inspect(mod_tree)
  end
end

Main.main()
