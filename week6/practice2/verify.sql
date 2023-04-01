SELECT TOP (7) [date], MA5, MA10 FROM [ncudb].[dbo].[stock_price]
WHERE stock_code = '2330'
ORDER BY [date] DESC