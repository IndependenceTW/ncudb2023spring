select * from ncudb.dbo.find_crossover_date('2330', 3)
where year(date) = 2022
order by date asc