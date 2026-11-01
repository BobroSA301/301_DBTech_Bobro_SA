#!/bin/bash

# Устанавливаем кодовую страницу Windows, если команда доступна.
if command -v chcp >/dev/null 2>&1; then
    chcp 65001
fi

# Создание базы данных из скрипта лабораторной работы 2.
sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, исключить пары с самими собой. Для каждой пары вывести имена пользователей и название фильма. Оставить первые 100 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT
    u1.name AS user1,
    u2.name AS user2,
    m.title AS movie
FROM ratings r1
JOIN ratings r2
    ON r1.movie_id = r2.movie_id
   AND r1.user_id < r2.user_id
JOIN users u1 ON u1.id = r1.user_id
JOIN users u2 ON u2.id = r2.user_id
JOIN movies m ON m.id = r1.movie_id
ORDER BY u1.name, u2.name, m.title
LIMIT 100;"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей. Вывести название фильма, имя пользователя, оценку и дату отзыва в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH latest_ratings AS (
    SELECT
        r.user_id,
        r.movie_id,
        r.rating,
        r.timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY r.user_id
            ORDER BY r.timestamp DESC
        ) AS rn
    FROM ratings r
)
SELECT
    m.title,
    u.name AS user_name,
    lr.rating,
    date(lr.timestamp, 'unixepoch') AS rating_date
FROM latest_ratings lr
JOIN users u ON u.id = lr.user_id
JOIN movies m ON m.id = lr.movie_id
WHERE lr.rn = 1
ORDER BY lr.timestamp DESC
LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным и минимальным средним рейтингом. Отсортировать по году выпуска и названию фильма. В колонке Рекомендуем указать Да для максимального рейтинга и Нет для минимального."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH movie_averages AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies m
    JOIN ratings r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
),
rating_limits AS (
    SELECT
        MAX(avg_rating) AS max_rating,
        MIN(avg_rating) AS min_rating
    FROM movie_averages
)
SELECT
    ma.title,
    ma.year,
    ROUND(ma.avg_rating, 3) AS avg_rating,
    CASE
        WHEN ma.avg_rating = rl.max_rating THEN 'Да'
        ELSE 'Нет'
    END AS 'Рекомендуем'
FROM movie_averages ma
CROSS JOIN rating_limits rl
WHERE ma.avg_rating = rl.max_rating
   OR ma.avg_rating = rl.min_rating
ORDER BY ma.year, ma.title;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    COUNT(*) AS ratings_count,
    ROUND(AVG(r.rating), 3) AS average_rating
FROM ratings r
JOIN users u ON u.id = r.user_id
WHERE u.gender = 'female'
  AND date(r.timestamp, 'unixepoch') >= '2010-01-01'
  AND date(r.timestamp, 'unixepoch') < '2013-01-01';"
echo " "

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Отсортировать по году выпуска и названию фильма. Оставить первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH movie_ratings AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies m
    JOIN ratings r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
),
ranked_movies AS (
    SELECT
        title,
        year,
        avg_rating,
        RANK() OVER (ORDER BY avg_rating DESC) AS rating_rank
    FROM movie_ratings
)
SELECT
    title,
    year,
    ROUND(avg_rating, 3) AS avg_rating,
    rating_rank
FROM ranked_movies
ORDER BY year, title
LIMIT 20;"
echo " "

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате Фамилия Имя|Дата регистрации."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    substr(name, instr(name, ' ') + 1)
    || ' ' ||
    substr(name, 1, instr(name, ' ') - 1)
    || '|' || register_date AS user_info
FROM users
ORDER BY register_date DESC, id DESC
LIMIT 10;"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10. Результат должен быть представлен одним столбцом."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1
    FROM numbers
    WHERE n < 100
)
SELECT
    printf(
        '%dx%d=%d',
        (n - 1) / 10 + 1,
        (n - 1) % 10 + 1,
        ((n - 1) / 10 + 1) * ((n - 1) % 10 + 1)
    ) AS multiplication
FROM numbers
ORDER BY n;"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies. Каждый жанр вывести в отдельной строке."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE genre_parts(rest, genre) AS (
    SELECT genres || '|', ''
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''
      AND genres <> '(no genres listed)'

    UNION ALL

    SELECT
        substr(rest, instr(rest, '|') + 1),
        substr(rest, 1, instr(rest, '|') - 1)
    FROM genre_parts
    WHERE rest <> ''
)
SELECT DISTINCT genre
FROM genre_parts
WHERE genre <> ''
ORDER BY genre;"
echo " "

echo "TASK04 ЗАВЕРШЁН"
