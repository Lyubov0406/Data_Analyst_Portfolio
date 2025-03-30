-- В данном скрипте приведены различные базовые SELECT запросы


-- Запросы включают использование:
-- Агрегатных функций 
-- Создания переменнных
-- Условных выражений, оператор CASE
-- Табличных выражений, оператор WITH
-- Соединение таблиц, оператор JOIN 
-- и пр.



-- № 1. Сколько уникальных исполнителей и коллабораций попали в топ?

SELECT COUNT(DISTINCT `artist(s)_name`) AS unique_artists_count
FROM songs;



-- № 2. Топ-5 наиболее прослушиваемых исполнителя в 2023?

SELECT `artist(s)_name`,
	   SUM(streams) AS sum_streams
FROM songs
GROUP BY `artist(s)_name`
ORDER BY 2 DESC 
LIMIT 5;



-- № 3. Исполнители с наибольшим числом треков в топе

SELECT `artist(s)_name`, COUNT(*) AS tracks_in_top  
FROM songs 
GROUP BY 1 
ORDER BY 2 DESC
LIMIT 5;  



-- № 4. Какие исполнители, имеющие более одного трека в топе, показывают наиболее высокие средние показатели streams (прослушиваемости) на трек? Сколько у них треков?

SELECT `artist(s)_name`,
	   ROUND(AVG(streams), 0)  AS avg_streams,
	   COUNT(*) AS cnt_tracks
FROM songs 
GROUP BY 1 
HAVING count(*) > 1
ORDER BY 2 DESC
LIMIT 5;



-- № 5. Топ-10 наиболее прослушиваемых треков за 2023

SELECT track_name,
	   `artist(s)_name`,
       streams
FROM songs
ORDER BY streams DESC
LIMIT 10;



-- № 6. Топ-5 наиболее прослушиваемых треков, выпущенных в 2023 (новинки года)

SELECT track_name,
	   `artist(s)_name`,
       streams
FROM songs
WHERE released_year = 2023
ORDER BY streams DESC
LIMIT 5;



-- № 7. Сколько треков, выпущенных в разные десятилетия, попали в топ?

SELECT CONCAT(FLOOR(released_year / 10) * 10, '-', FLOOR(released_year / 10) * 10 + 9) AS decade,
       COUNT(*) AS songs_count
FROM songs
GROUP BY 1
ORDER BY 1;



-- № 8. Какой темп и модальность у наиболее прослушиваемых треков

SELECT   track_name,
         `artist(s)_name`,
         bpm,
         mode
FROM     songs
ORDER BY streams DESC
LIMIT    10;



-- № 9. Каков темп и процентное соотношение минорной и мажорной модальности у треков в топе, вышедших в разные десятилетия?

SELECT CONCAT(FLOOR(released_year / 10) * 10, '-', FLOOR(released_year / 10) * 10 + 9) AS decade,
       COUNT(*) AS songs_count,
       ROUND((AVG(bpm)), 0) AS avg_bpm, 
       ROUND((SUM(IF(mode = 'Major', 1, 0)) / COUNT(*) * 100), 0) AS major_songs_pct,
       ROUND((SUM(IF(mode = 'Minor', 1, 0)) /COUNT(*) * 100), 0) AS minor_songs_pct
FROM songs
GROUP BY 1
ORDER BY 1;


-- № 10. Каково соотношение «счастливых» (valence > 70%) и «грустных» (valence < 30%) треков в топе?

SET @cnt_low_valence := (SELECT count(*) FROM songs WHERE `valence_%` < 30);
SET @cnt_high_valence := (SELECT count(*) FROM songs WHERE `valence_%`> 70);

SELECT ROUND((@cnt_low_valence / count(*) * 100), 0) AS `happy_tracks_%`,
	   ROUND((@cnt_high_valence / count(*) * 100), 0) AS `sad_tracks_%`,
	   ROUND(((count(*) - @cnt_low_valence - @cnt_high_valence) / count(*) * 100), 0) AS  `neutral_tracks_%`
FROM songs;



-- № 11. Сколько песен в каждой из тональностей попало в топ? 

SELECT `key`, 
	   COUNT(*)
FROM songs
WHERE `key` NOT IN ('') -- в датасете есть треки без указания Key, но вместо NULL в этих ячейках просто не содержится никаких символов ('')
GROUP BY 1
ORDER BY 2 DESC;



-- № 12. Сезонный анализ. Сколько треков, выпущенных в каждый из сезонов года, попали в топ? Какая у них прослушиваемость? 
 
SELECT 
    CASE 
        WHEN released_month  IN (12, 1, 2) THEN 'Winter'
        WHEN released_month IN (3, 4, 5) THEN 'Spring'
        WHEN released_month IN (6, 7, 8) THEN 'Summer'
        WHEN released_month IN (9, 10, 11) THEN 'Autumn'
    END AS season,
    COUNT(*) AS tracks_count,
    AVG(streams) AS avg_streams,
    MAX(streams) AS max_streams,
    MIN(streams) AS min_streams
FROM songs
GROUP BY 1
ORDER BY 1;



-- № 13. Сезонный анализ. Какие средние показатели танцевальности, энергичности и позитивности треков, вышедших в разные сезоны года?

SELECT 
    CASE 
        WHEN released_month  IN (12, 1, 2) THEN 'Winter'
        WHEN released_month IN (3, 4, 5) THEN 'Spring'
        WHEN released_month IN (6, 7, 8) THEN 'Summer'
        WHEN released_month IN (9, 10, 11) THEN 'Autumn'
    END AS season,
    AVG(`danceability_%`) AS avg_danceability,
    AVG(`energy_%`) AS avg_energy,
    AVG(`valence_%`) AS avg_valence
FROM songs
GROUP BY 1
ORDER BY 1;



-- № 14. Какие треки входят в топ 10 по количеству попадений в чарты одновременно и на Spotify, и в Apple Music

WITH spotify_charts
AS (
SELECT track_name AS track_name_spotify_charts, 
	   `artist(s)_name`,
	   in_spotify_charts
FROM songs
ORDER BY 3 DESC 
LIMIT 10),
apple_charts
AS (
SELECT track_name AS track_name_apple_charts, 
	   `artist(s)_name`,
	   in_apple_charts
FROM songs
ORDER BY 3 DESC 
LIMIT 10)
SELECT track_name_spotify_charts, 
	   in_spotify_charts,
	   in_apple_charts
FROM spotify_charts
	 INNER JOIN apple_charts ON track_name_spotify_charts = track_name_apple_charts;



-- № 15. Какие треки входят в топ 10 по количеству добавлений в плейлисты на всех платформах (Spotify, Apple Music, Deezer)

WITH spotify_charts
AS (
SELECT track_name AS track_name_spotify_charts, 
	   `artist(s)_name`,
	   in_spotify_playlists 
FROM songs
ORDER BY 3 DESC 
LIMIT 10),
apple_charts
AS (
SELECT track_name AS track_name_apple_charts, 
	   `artist(s)_name`,
	   in_apple_playlists 
FROM songs
ORDER BY 3 DESC 
LIMIT 10),
deezer_charts 
AS (
SELECT track_name AS track_name_deezer_charts, 
	   `artist(s)_name`,
	   in_deezer_playlists 
FROM songs
ORDER BY 3 DESC 
LIMIT 10)
SELECT track_name_spotify_charts, 
	   in_spotify_playlists,
	   in_apple_playlists, 
	   in_deezer_playlists 
FROM spotify_charts
	 JOIN apple_charts ON track_name_spotify_charts = track_name_apple_charts
	 JOIN deezer_charts ON track_name_apple_charts = track_name_deezer_charts;



