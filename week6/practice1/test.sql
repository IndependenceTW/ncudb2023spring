USE [ncudb]

DECLARE @Day int 
DECLARE @Result char(50)

EXEC [dbo].[Trend_Analysis] '2330', @Day OUTPUT, @Result OUTPUT

print(@Day)
PRINT(@Result)