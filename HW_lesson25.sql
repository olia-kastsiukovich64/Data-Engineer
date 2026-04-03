/*
 Задача:
1. Приведите таблицу к 1НФ

   Исходная таблица на картинке уже удовлетворяет базовым требованиям 1НФ - все данные атомарны и записи уникальные.
   Первичным ключом здесь будет составной ключ - PK (КУРС_ID, СТУДЕНТ_ID)

2. Приведите таблицу к 2НФ
	Требования 2НФ: Таблица находится в 1НФ, все неключевые атрибуты зависят только от первичного ключа.
	В нашей 1НФ таблице есть проблема: атрибуты НАЗВАНИЕ, ПРЕПОДАВАТЕЛЬ, КАФЕДРА и ТЕЛЕФОН_КАФЕДРЫ зависят только от КУРС_ID. 
	Атрибут СТУДЕНТ_ИМЯ зависит только от СТУДЕНТ_ID. 
	И только ОЦЕНКА зависит от всего составного ключа целиком.
	Поэтому для 2НФ нужно разбить таблицу на три сущности:
	
		1. Курсы 
			PK КУРС_ID
			НАЗВАНИЕ
			ПРЕПОДАВАТЕЛЬ
			КАФЕДРА
			ТЕЛЕФОН_КАФЕДРЫ
			
		2.Студенты  (students)
			PK СТУДЕНТ_ID
			СТУДЕНТ_ИМЯ

		3.Оценки
			PK, FK КУРС_ID
			PK, FK СТУДЕНТ_ID
			ОЦЕНКА

3. Приведите таблицу к 3НФ
	Требования 3НФ: Таблица находится в 2НФ, отсутствуют транзитивные зависимости 
	(неключевые атрибуты не должны зависеть от других неключевых атрибутов).
	Таблицы «Студенты» и «Оценки» уже в 3НФ. А вот в таблице «Курсы» есть транзитивная зависимость: 
	ТЕЛЕФОН_КАФЕДРЫ зависит от КАФЕДРА, а не напрямую от КУРС_ID.
	Поэтому выносим кафедры в отдельную таблицу:
	
		1. Кафедры (departments)
			PK НАЗВАНИЕ_КАФЕДРЫ
			ТЕЛЕФОН_КАФЕДРЫ
			
	Таблица курсы примет вид:
		2. Курсы (courses)
			PK КУРС_ID
			НАЗВАНИЕ
			ПРЕПОДАВАТЕЛЬ
			FK НАЗВАНИЕ_КАФЕДРЫ
					
4*. Создайте ER-диаграмму на основе 1,2,3 пунктов
*/

create table departments (
    department_name varchar(100) primary key,
    department_phone varchar(20) not null
);

create table courses (
	course_id serial primary key,
	course_name varchar(100) not null,
	teacher_name varchar(100) not null,
	department_name varchar(100) not null,
	foreign key (department_name) references departments(department_name) 
	);

create table students (
    student_id int primary key,
    student_name varchar(100) not null
);

create table grades (
    course_id int, 
    student_id int, 
    grade int,
    primary key (course_id, student_id),
	foreign key (course_id) references courses(course_id),
	foreign key (student_id) references students(student_id)
	);



