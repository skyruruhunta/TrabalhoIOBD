DROP DATABASE IF EXISTS Portal;

CREATE DATABASE Portal;

\c Portal;

DROP SCHEMA IF EXISTS conteudo;
CREATE SCHEMA conteudo;

DROP SCHEMA IF EXISTS usuarios;
CREATE SCHEMA usuarios;

SET search_path TO conteudo, usuarios;

CREATE TABLE usuarios.usuario (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    nome VARCHAR(50) NOT NULL,
    senha VARCHAR(15) NOT NULL,
    data_cadastro DATE NOT NULL DEFAULT CURRENT_DATE,
    data_nascimento DATE,
    bairro VARCHAR(100),
    complemento VARCHAR(100),
    nro VARCHAR(10),
    cep VARCHAR(10),
    rua VARCHAR(100)
);

CREATE TABLE usuarios.telefone (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios.usuario(id) ON DELETE CASCADE,
    numero VARCHAR(15) NOT NULL,
    tipo VARCHAR(20) 
);
INSERT INTO usuarios.usuario (email, nome, senha, data_nascimento, bairro, complemento, nro, cep, rua) 
VALUES
    ('a@gmail.com', 'adriano', '123', '1999-12-06', 'Centro', 'sim', '223', '12345-6789', 'aquela'),
    ('b@gmail.com', 'bruno', '123', '2001-06-10', 'Cidade-nova', 'sim', '224', '12345-6781', 'aquela ali'),
    ('c@gmail.com', 'carlos', '123', '1988-03-15', 'BGV', 'sim', '225', '12345-6782', 'aquela lá');

INSERT INTO usuarios.telefone (usuario_id, numero, tipo)
VALUES 
    (1, '123456789', 'Celular'),
    (1, '987654321', 'Residencial'),
    (2, '1234567891', 'Celular'),
    (3, '1234567892', 'Comercial');

CREATE TABLE conteudo.categoria (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

INSERT INTO conteudo.categoria (nome)
VALUES 
    ('Tecnologia'),
    ('Ciência'),
    ('Arte');

CREATE TABLE conteudo.artigo (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    conteudo TEXT NOT NULL,
    data_publicacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    categoria_id INT REFERENCES conteudo.categoria(id)
);

INSERT INTO conteudo.artigo (titulo, conteudo, data_publicacao, categoria_id)
VALUES
    ('Inovações em IA', 'Este artigo discute as últimas inovações em inteligência artificial.', '2024-10-15 14:30:00', 1),
    ('Exploração Espacial', 'Um mergulho nas novas descobertas sobre o espaço.', '2024-10-16 15:45:00', 2),
    ('Pintura e Criatividade', 'Explorando a relação entre pintura e processos criativos.', '2024-10-17 10:00:00', 3),
    ('Física Moderna', 'Entenda os princípios da física moderna.', '2024-10-18 11:15:00', 2);

CREATE TABLE conteudo.artigo_usuario (
    usuario_id INT REFERENCES usuarios.usuario(id),
    artigo_id INT REFERENCES conteudo.artigo(id),
    PRIMARY KEY (usuario_id, artigo_id)
);

INSERT INTO conteudo.artigo_usuario (usuario_id, artigo_id)
VALUES
    (1, 1),
    (2, 2), 
    (1, 3), 
    (3, 4), 
    (2, 1); 

CREATE TABLE conteudo.comentario (
    id SERIAL PRIMARY KEY,
    conteudo TEXT NOT NULL,
    data_comentario TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT REFERENCES usuarios.usuario(id),
    artigo_id INT REFERENCES conteudo.artigo(id)
);

INSERT INTO conteudo.comentario (conteudo, data_comentario, usuario_id, artigo_id)
VALUES
    ('Muito interessante!', '2024-10-15 15:00:00', 2, 1),
    ('Excelente artigo!', '2024-10-16 16:00:00', 1, 2),
    ('Gostei da abordagem.', '2024-10-17 11:30:00', 3, 1),
    ('Fascinante!', '2024-10-18 12:00:00', 1, 4);

CREATE TABLE conteudo.curtida (
    id SERIAL PRIMARY KEY,
    data_curtida TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT REFERENCES usuarios.usuario(id),
    artigo_id INT REFERENCES conteudo.artigo(id)
);

INSERT INTO conteudo.curtida (data_curtida, usuario_id, artigo_id)
VALUES
    ('2024-10-15 15:10:00', 2, 1),
    ('2024-10-16 16:10:00', 1, 2),
    ('2024-10-17 12:00:00', 3, 1),
    ('2024-10-18 12:30:00', 1, 4);

-- 1. Quais usuários escreveram mais artigos? Em caso de empate mostrar todos
SELECT u.nome, COUNT(au.artigo_id) AS total_artigos
FROM usuarios.usuario u
JOIN conteudo.artigo_usuario au ON u.id = au.usuario_id
GROUP BY u.id
HAVING COUNT(au.artigo_id) = (
    SELECT MAX(total)
    FROM (
        SELECT COUNT(artigo_id) AS total
        FROM conteudo.artigo_usuario
        GROUP BY usuario_id
    ) AS artigo_contagem
);

-- 2. O título de cada Artigo e o nome de cada usuário envolvido na escrita de cada Artigo
SELECT titulo, nome 
FROM conteudo.artigo 
JOIN conteudo.artigo_usuario ON conteudo.artigo.id = conteudo.artigo_usuario.artigo_id 
JOIN usuarios.usuario ON conteudo.artigo_usuario.usuario_id = usuarios.usuario.id;

-- 3. Listar os Usuários com e sem endereços. Caso tenha endereço, coloque o endereço. Se não tiver, coloque "Sem endereço cadastrado"
SELECT nome, 
       COALESCE(
           CONCAT('Bairro: ', bairro, ', Rua: ', rua, ', Número: ', nro, ', CEP: ', cep), 
           'Sem endereço cadastrado'
       ) AS endereco
FROM usuarios.usuario;

-- 4. Criar uma View com informações dos artigos
CREATE VIEW conteudo.artigo_usuario_vw AS
SELECT 
    a.titulo,
    a.conteudo,
    TO_CHAR(a.data_publicacao, 'DD/MM/YYYY') AS data_publicacao,
    c.nome AS categoria,
    u.nome AS autor
FROM conteudo.artigo a
JOIN conteudo.artigo_usuario au ON a.id = au.artigo_id
JOIN usuarios.usuario u ON au.usuario_id = u.id
LEFT JOIN conteudo.categoria c ON a.categoria_id = c.id;

SELECT * FROM conteudo.artigo_usuario_vw;