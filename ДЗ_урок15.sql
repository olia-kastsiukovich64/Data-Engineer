CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    birth_year INTEGER,
    country TEXT,
    bio TEXT
);
CREATE TABLE books (
    book_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    year INTEGER,
    author_id INTEGER,
    genre_id INTEGER,
    quantity INTEGER,
    status TEXT,
    FOREIGN KEY (author_id) REFERENCES authors (author_id)
);

CREATE TABLE readers (
    reader_id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    ticket_number TEXT UNIQUE,
    reg_date DATE DEFAULT CURRENT_DATE,
    phone TEXT,
    email TEXT
);

CREATE TABLE genres (
    genre_id INTEGER PRIMARY KEY AUTOINCREMENT,
    genre_name TEXT NOT NULL
);

CREATE TABLE book_loans (
    loan_id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id INTEGER NOT NULL,
    reader_id INTEGER NOT NULL,
    loan_date DATE DEFAULT CURRENT_DATE,
    return_date DATE,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (reader_id) REFERENCES readers(reader_id)
);

INSERT INTO authors (full_name, birth_year, country, bio) VALUES
('Дмитрий Глуховский', 1979, 'Россия', 'Российский писатель, автор антиутопий.'),
('Стивен Кинг', 1947, 'США', 'Американский писатель, автор хорроров.'),
('Дж.К. Роулинг', 1965, 'Великобритания', 'Автор серии о Гарри Поттере.');

SELECT * FROM authors

INSERT INTO genres (genre_name) VALUES
('Фантастика'),
('Ужасы'),
('Фэнтези'); 

SELECT * FROM genres 

INSERT INTO books (title, year, author_id, genre_id, quantity, status) VALUES
('Метро 2033', 2005, 1, 1, 4, 'доступна'),
('Оно', 1986, 2, 2, 2, 'на руках'),
('Гарри Поттер и философский камень', 1997, 3, 3, 5, 'доступна'),
('Темная башня', 1982, 2, 1, 3, 'в ремонте');

SELECT * FROM books

INSERT INTO readers (full_name, ticket_number, phone, email) VALUES
('Иван Петров', 'T12345', '+79000000001', 'ivan.petrov@example.com'),
('Анна Смирнова', 'T12346', '+79000000002', 'anna.smirnova@example.com'),
('Сергей Иванов', 'T12347', '+79000000003', 'sergey.ivanov@example.com');

SELECT * FROM readers

INSERT INTO book_loans (book_id, reader_id, loan_date, return_date) VALUES
(2, 1, '2026-01-10', NULL),
(1, 2, '2026-01-05', '2026-01-20');

SELECT * FROM book_loans

SELECT
    author_id,
    COUNT(*) AS number_books
FROM books
GROUP BY author_id;

SELECT *
FROM books
WHERE title LIKE '%о%';