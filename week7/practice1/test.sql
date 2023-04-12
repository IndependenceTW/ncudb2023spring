DECLARE @return_date DATE
DECLARE @result CHAR(50)

EXEC ncudb.dbo.candlestick_twoDays_type_SP '2330', @return_date OUTPUT, @result OUTPUT
PRINT('2330: ')
PRINT(@return_date)
PRINT(@result)
PRINT('-------')

EXEC ncudb.dbo.candlestick_twoDays_type_SP '2317', @return_date OUTPUT, @result OUTPUT
PRINT('2317: ')
PRINT(@return_date)
PRINT(@result)
PRINT('-------')