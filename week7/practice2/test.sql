DECLARE @type int
EXEC ncudb.dbo.price_type '2330',20, '2022-01-05', @type OUTPUT
PRINT(@type)
EXEC ncudb.dbo.price_type '2330',20, '2022-02-08', @type OUTPUT
PRINT(@type)
EXEC ncudb.dbo.price_type '2330',20, '2022-04-25', @type OUTPUT
PRINT(@type)