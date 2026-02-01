"""Задача 1: Есть входной файлик по информации по людям, необходимо подготовить отчет в формате .txt в любом виде
с информацией о том, сколько по каждой профессии у нас людей, сколько людей в каждом городе и сколько людей в стране.

Вывод в файлике statistics.txt:
Статистика по профессиям:
программист: 10 человек
учительница: 17 человек
...

Статистика по городам:
Минск: 3 человек
Москва: 1 человек
...

Статистика по странам:
Беларусь: 23 человек
Россия: 26 человек ... профессии должны быть уникальными/ через словарь ключ-значение/счетчик """

def collect_statistics (index): 
    with open('files/filename.txt', 'r', encoding='utf-8') as file:
        lines = file.readlines()

        statistics = {}
        for line in lines:
            key = line.split(', ')[-index]
            print(key)
            if key in statistics.keys():
                statistics[key] += 1
            else:
                statistics[key] = 1
        print(statistics)
    with open('statistics.txt', 'a') as s:
        s.write(f"\n=== Cтатистика по index = {index} ====\n")
        for k, v in statistics.items():
            s.write(f"{k}:{v}\n")

collect_statistics (3)
collect_statistics (2)
collect_statistics (1)

"""with open('statistics.txt', 'w') as s:
        for k, v in position.items():
            s.write(f"{k}:{v}\n")

with open('files/filename.txt', 'r', encoding='utf-8') as file:
    lines = file.readlines()

    cities = {}
    for line in lines:
        city = line.split(', ')[-2]
        print(city)
        if city in cities.keys():
            cities[city] += 1
        else:
            cities[city] = 1

    print(cities)

    with open('statistics.txt', 'w') as s:
        for m, n in cities.items():
            s.write(f"{m}:{n}\n")

with open('files/filename.txt', 'r', encoding='utf-8') as file:
    lines = file.readlines()

    countries = {}
    for line in lines:
        country = line.split(', ')[-1]
        print(country)
        if country in countries.keys():
            countries[country] += 1
        else:
            countries[country] = 1

    print(countries)

with open('statistics.txt', 'w') as s:
        for k, v in countries.items():
            s.write(f"{k}:{v}\n")
        for m, n in cities.items():
            s.write(f"{m}:{n}\n")
        for l, p in position.items():
            s.write(f"{l}:{p}\n")"""


