-- В данном скрипте приведены различные комплексные SELECT запросы

-- Запросы включают использование:
-- Различных функций для работы с текстом и датой
-- Создания переменнных
-- Условных выражений, оператор CASE
-- Табличных выражений, оператор WITH
-- Оконных функций, оператор OVER, ORDER BY/PARTITION BY
-- и пр.



-- №1. Отнести каждого студента к группе,  в зависимости от пройденных заданий:
-- Интервал	Группа
-- от 0 до 10	I
-- от 11 до 15	II
-- от 16 до 27	III
-- больше 27	IV

-- Пройденными считаются задания с хотя бы одним верным ответом.
-- Посчитать, сколько студентов относится к каждой группе. 

SELECT CASE
           WHEN rate < 11 THEN 'I'
           WHEN rate < 16 THEN 'II'
           WHEN rate < 28 THEN 'III'
           ELSE 'IV'
           END AS Группа,
       CASE
           WHEN rate < 11 THEN 'от 0 до 10'
           WHEN rate < 16 THEN 'от 11 до 15'
           WHEN rate < 28 THEN 'от 16 до 27'
           ELSE 'больше 27'
           END AS Интервал,
       COUNT(student_name) AS Количество
FROM (       
    SELECT student_name, 
           COUNT(step_id) AS rate
    FROM student 
    	INNER JOIN step_student USING(student_id)
    WHERE result = "correct"
    GROUP BY student_name
    ORDER BY rate) AS q_in
GROUP BY Группа, Интервал
ORDER BY 1;



-- № 2. Для каждого шага вывести процент правильных решений. 
-- Для шагов, которые  не имеют неверных ответов,  указать 100 как процент успешных попыток, если же шаг не имеет верных ответов, указать 0. 
-- Информацию отсортировать сначала по возрастанию успешности, а затем по названию шага в алфавитном порядке.

WITH get_count_correct (st_n_c, count_correct)
  AS (
	SELECT step_name, count(*)
	FROM step s 
		 JOIN step_student ss USING (step_id)
	WHERE result = "correct"
	GROUP BY 1),
get_count_wrong (st_n_w, count_wrong)
  AS (
	SELECT step_name, count(*)
	FROM step s 
		 JOIN step_student ss USING (step_id)
	WHERE result = "wrong"
	GROUP BY 1)
SELECT st_n_c AS Шаг, IFNULL(round(count_correct / (count_correct + count_wrong) * 100), 100) AS Успешность
FROM get_count_correct 
    LEFT JOIN get_count_wrong ON st_n_c = st_n_w
UNION -- UNION используем, потому что необходимо реализовать FULL JOIN, который не поддерживается в MySQL
SELECT st_n_w AS Шаг,
    IFNULL(ROUND(count_correct / (count_correct + count_wrong) * 100), 0) AS Успешность
FROM get_count_correct 
    RIGHT JOIN get_count_wrong ON st_n_c = st_n_w
ORDER BY 2, 1;



-- № 3. Вычислить прогресс пользователей по курсу. 
-- Прогресс вычисляется как отношение верно пройденных шагов к общему количеству шагов в процентах, округленное до целого. 
-- Тем пользователям, которые прошли все шаги выдать "Сертификат с отличием". Тем, у кого прогресс больше или равен 80% -  "Сертификат". 
-- Для остальных записей в столбце Результат задать пустую строку ("").
-- Информацию отсортировать по убыванию прогресса, затем по имени пользователя в алфавитном порядке.

SET @max_progress := (SELECT COUNT(DISTINCT step_id) FROM step_student); -- введем переменную для облегчения кода

SELECT student_name as Студент, ROUND(COUNT(DISTINCT CASE WHEN result = 'correct' THEN step_id END) / @max_progress * 100) AS Прогресс, 
	   CASE 
	   	WHEN ROUND(COUNT(DISTINCT CASE WHEN result = 'correct' THEN step_id END) / @max_progress * 100) < 80 THEN ''
	   	WHEN ROUND(COUNT(DISTINCT CASE WHEN result = 'correct' THEN step_id END) / @max_progress * 100) BETWEEN 80 AND 99 THEN 'Сертификат'
	   	WHEN ROUND(COUNT(DISTINCT CASE WHEN result = 'correct' THEN step_id END) / @max_progress * 100) = 100 THEN 'Сертификат с отличием'
	   END AS Результат
FROM student 
	 LEFT JOIN step_student USING (student_id)
GROUP BY 1
ORDER BY 2 DESC, 1;



-- № 4. Для студента с именем student_61 вывести все его попытки: название шага, результат и дату отправки попытки. 
-- Информацию отсортировать по дате отправки попытки и указать, сколько минут прошло между отправкой соседних попыток. 
-- Название шага ограничить 20 символами и добавить "...". Столбцы назвать Студент, Шаг, Результат, Дата_отправки, Разница.

SELECT student_name AS Студент, 
	   concat(LEFT(step_name, 20), '...') AS Шаг, 
	   result AS Результат, 
	   FROM_UNIXTIME(submission_time) AS Дата_отправки,  
	   sec_to_time(ifnull(submission_time - LAG(submission_time) OVER (ORDER BY submission_time), 0)) AS Разница 
FROM student
	 JOIN step_student USING (student_id)
	 JOIN step USING (step_id)
WHERE student_name = 'student_61'
ORDER BY 4;



-- № 5. Вычислить рейтинг каждого студента относительно студента, прошедшего наибольшее количество шагов в модуле (вычисляется как отношение количества пройденных студентом шагов к максимальному количеству пройденных шагов, умноженное на 100). 
-- Вывести номер модуля, номер студента, количество пройденных им шагов и относительный рейтинг. 
-- Относительный рейтинг округлить до одного знака после запятой. 
-- Информацию отсортировать сначала по возрастанию номера модуля, потом по убыванию относительного рейтинга и, наконец, по имени студента в алфавитном порядке.

WITH steps_for_student_per_mod
AS (
SELECT module_id, student_name, count(DISTINCT step_id) AS count_step
FROM module 
		 JOIN lesson USING(module_id)
		 JOIN step USING (lesson_id)
		 JOIN step_student USING (step_id)
		 JOIN student USING (student_id)
WHERE result = 'correct'
GROUP BY 1, 2
),
the_most_seccessfull
AS (
	SELECT DISTINCT module_id, max(count_step) 
					  OVER (PARTITION BY module_id) AS max_count
	FROM steps_for_student_per_mod
)
SELECT module_id AS Модуль, 
	   student_name AS Студент, 
	   count_step AS Пройдено_шагов, 
	   round(count_step / max_count * 100, 1) AS Относительный_рейтинг
FROM steps_for_student_per_mod
	 JOIN the_most_seccessfull USING (module_id)
ORDER BY 1, 4 DESC, 2;


select concat(module_id, '.', lesson_position, '.', if(length(step_position) < 2, LPAD(step_position, 2, '0'), step_position), ' ', step_name) as Шаг 
from module 
inner join lesson using(module_id)
inner join step using(lesson_id)
inner join step_keyword using(step_id)
inner join keyword using(keyword_id)
where keyword_name = 'MAX' or keyword_name = 'AVG'
group by 1
having count(keyword_name) = 2
order by 1;