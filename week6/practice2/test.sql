USE [ncudb]

DECLARE @result CHAR(50)
EXEC MA_Analysis '2330', 'MA5', 'MA10', @result OUTPUT

PRINT(@result)