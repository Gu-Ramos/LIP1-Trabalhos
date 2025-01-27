use raylib::prelude::*;

#[allow(dead_code)]
/// Um nó, ou vértice, de uma árvore binária
struct BTreeNode<'a> {
    id: &'a str,                       // ID do vértice
    val: i32,                          // valor armazenado no vértice
    right: Option<Box<BTreeNode<'a>>>, // Filho direito
    left: Option<Box<BTreeNode<'a>>>,  // Filho esquerdo
    x: f32,
    y: f32, // Posição x,y do vértice (para quesito de representação gráfica)
}

/// Calcula as posições dos nós recursivamente. Retorna a posição x de um nó e o limite direito dele (o X do filho/neto/etc dele mais à direita)
/// Essa função tenta ser estritamente funcional, apesar de rust não ser bem uma linguagem funcional.
fn calculate_positions(
    tree: BTreeNode,
    level: i32,
    scale: f32,
    left_limit: f32,
) -> (BTreeNode, f32) {
    // O y do nó sempre vai ser dependente apenas do nível dele e da escala desejada.
    let y = scale * (level as f32);

    match tree {
        // Caso onde o nó não tem filhos
        BTreeNode {
            left: None,
            right: None,
            ..
        } => {
            let x = left_limit;
            (BTreeNode { x: x, y: y, ..tree }, left_limit)
        }

        // Caso onde o nó só tem o filho esquerdo
        BTreeNode {
            left: Some(left_child),
            right: None,
            ..
        } => {
            // calcula a posição do filho esquerdo
            let (left_child, right_limit) =
                calculate_positions(*left_child, level + 1, scale, left_limit);
            // como ele só tem um filho, a posição X dele vai ser a mesma do filho dele. (isto é, ele vai estar diretamente acima do filho dele.)
            (
                BTreeNode {
                    x: left_child.x,
                    y: y,
                    left: Some(Box::new(left_child)),
                    ..tree
                },
                right_limit,
            )
        }

        // Caso onde o nó só tem o filho direito
        BTreeNode {
            left: None,
            right: Some(right_child),
            ..
        } => {
            // mesma lógica da função acima
            let (right_child, right_limit) =
                calculate_positions(*right_child, level + 1, scale, left_limit);
            (
                BTreeNode {
                    x: right_child.x,
                    y: y,
                    right: Some(Box::new(right_child)),
                    ..tree
                },
                right_limit,
            )
        }

        // Caso onde o nó tem os dois filhos
        BTreeNode {
            left: Some(left_child),
            right: Some(right_child),
            ..
        } => {
            // calcula as posições dos dois filhos
            let (left_child, lchild_right_limit) =
                calculate_positions(*left_child, level + 1, scale, left_limit);
            let (right_child, rchild_right_limit) =
                calculate_positions(*right_child, level + 1, scale, lchild_right_limit + scale);
            // o nó vai estar no meio dos dois filhos
            (
                BTreeNode {
                    x: (left_child.x + right_child.x) / 2.0,
                    y: y,
                    left: Some(Box::new(left_child)),
                    right: Some(Box::new(right_child)),
                    ..tree
                },
                rchild_right_limit,
            )
        }
    }
}

/// Função pra printar a árvore recursivamente no terminal
fn print_tree(node: &BTreeNode, level: usize) {
    // nível -> id -> valor -> coordenada x -> coordenada y
    println!(
        "{}{} ({}), x: {}, y: {}",
        "  ".repeat(level),
        node.id,
        node.val,
        node.x,
        node.y
    );

    if let Some(left) = &node.left {
        print_tree(left, level + 1);
    }
    if let Some(right) = &node.right {
        print_tree(right, level + 1);
    }
}

fn main() {
    // árvore teste
    let tree = BTreeNode {
        id: "a",
        val: 10,
        left: Some(Box::new(BTreeNode {
            id: "b",
            val: 5,
            left: None,
            right: None,
            x: 0.0,
            y: 0.0,
        })),
        right: Some(Box::new(BTreeNode {
            id: "c",
            val: 15,
            left: None,
            right: Some(Box::new(BTreeNode {
                id: "d",
                val: 20,
                left: Some(Box::new(BTreeNode {
                    id: "e",
                    val: 18,
                    left: Some(Box::new(BTreeNode {
                        id: "g",
                        val: 17,
                        left: None,
                        right: None,
                        x: 0.0,
                        y: 0.0,
                    })),
                    right: Some(Box::new(BTreeNode {
                        id: "h",
                        val: 19,
                        left: None,
                        right: None,
                        x: 0.0,
                        y: 0.0,
                    })),
                    x: 0.0,
                    y: 0.0,
                })),
                right: Some(Box::new(BTreeNode {
                    id: "f",
                    val: 25,
                    left: None,
                    right: None,
                    x: 0.0,
                    y: 0.0,
                })),
                x: 0.0,
                y: 0.0,
            })),
            x: 0.0,
            y: 0.0,
        })),
        x: 0.0,
        y: 0.0,
    };

    // calcula as posições dos nós
    let scale = 30.0;
    let (tree, _) = calculate_positions(tree, 0, scale, -100.0);

    // printa a árvore no terminal
    print_tree(&tree, 0);

    // setup da biblioteca raylib
    let (mut rl, thread) = raylib::init()
        .log_level(TraceLogLevel::LOG_NONE)
        .vsync()
        .size(640, 480)
        .title("Hello, World")
        .build();
    rl.set_window_monitor(0);

    let mut camera = Camera2D {
        target: Vector2::new(0.0, 0.0),
        offset: Vector2::new(320.0, 240.0), // centraliza a câmera no 0,0
        rotation: 0.0,
        zoom: 2.0,
    };

    // main loop da interface
    while !rl.window_should_close() {
        // controle da câmera
        if rl.is_key_down(KeyboardKey::KEY_UP) {
            camera.target.y -= 2.0;
        }
        if rl.is_key_down(KeyboardKey::KEY_DOWN) {
            camera.target.y += 2.0;
        }
        if rl.is_key_down(KeyboardKey::KEY_RIGHT) {
            camera.target.x += 2.0;
        }
        if rl.is_key_down(KeyboardKey::KEY_LEFT) {
            camera.target.x -= 2.0;
        }

        let mut d = rl.begin_drawing(&thread);
        let mut dc: RaylibMode2D<'_, RaylibDrawHandle<'_>> = d.begin_mode2D(camera);

        // desenha o background e a árvore
        dc.clear_background(Color::BLACK);
        draw_tree(&tree, &mut dc);
    }
}

// Desenha a árvore recursivamente
fn draw_tree(tree: &BTreeNode, dc: &mut RaylibMode2D<'_, RaylibDrawHandle<'_>>) {
    // Desenha os filhos e as conexões, se eles existirem
    if let Some(left_child) = &tree.left {
        dc.draw_line(
            tree.x as i32,
            tree.y as i32,
            left_child.x as i32,
            left_child.y as i32,
            Color::WHITE,
        );
        draw_tree(&left_child, dc);
    }
    if let Some(right_child) = &tree.right {
        dc.draw_line(
            tree.x as i32,
            tree.y as i32,
            right_child.x as i32,
            right_child.y as i32,
            Color::WHITE,
        );
        draw_tree(&right_child, dc);
    }

    // Desenha o nó
    dc.draw_circle(tree.x as i32, tree.y as i32, 8.0, Color::ORANGERED);

    // Desenha as informações do nó
    dc.draw_text(
        tree.id,
        tree.x as i32 + 2,
        tree.y as i32 + 2,
        10,
        Color::WHITE,
    );
    dc.draw_text(
        &tree.val.to_string(),
        tree.x as i32 - 4,
        tree.y as i32 - 6,
        12,
        Color::WHITE,
    );
}
