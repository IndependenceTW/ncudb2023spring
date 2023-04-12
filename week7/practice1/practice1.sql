USE ncudb
GO
CREATE OR ALTER PROCEDURE dbo.candlestick_twoDays_type_SP
    @company_input VARCHAR(10),
    @return_date DATE OUTPUT,
    @result CHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @today_o REAL, @today_c REAL
    DECLARE @yesterday_o REAL, @yesterday_c REAL
    DECLARE @last_working_date DATE
    DECLARE @date DATE
    DECLARE @today_type INT, @yesterday_type INT

    SET @result = '99'

    DECLARE cur CURSOR LOCAL FOR 
        SELECT [date], o, c
        FROM dbo.stock_price
        WHERE stock_code = @company_input
        ORDER BY [date] DESC
    OPEN cur

    FETCH NEXT FROM cur INTO @last_working_date, @yesterday_o, @yesterday_c
    SELECT @yesterday_type=[type] FROM ncudb.dbo.candlestick_type(@company_input, @last_working_date)

    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @today_type = @yesterday_type
        SET @today_c = @yesterday_c
        SET @today_o = @yesterday_o
        SET @date = @last_working_date
        FETCH NEXT FROM cur INTO @last_working_date, @yesterday_o, @yesterday_c
        
        IF @@FETCH_STATUS!=0
            BREAK
        
        SELECT @yesterday_type=[type] FROM ncudb.dbo.candlestick_type(@company_input, @last_working_date)

        IF @today_type * @yesterday_type < 0
        BEGIN
            --遭遇線判斷
            IF (@yesterday_c=@today_c)
            BEGIN
                IF (ABS(@today_type) = 4 AND ABS(@yesterday_type) = 4)
                BEGIN
                    SET @return_date = @date
                    IF (@today_type>0)
                        SET @result = '多頭遭遇線'
                    ELSE
                        SET @result = '空頭遭遇線'
                    BREAK
                END
            END
            --多頭各種線判斷 黑紅
            ELSE IF (@yesterday_type<0)
            BEGIN
                IF (@yesterday_c<@today_o AND @yesterday_o>@today_c)
                BEGIN
                    SET @return_date = @date
                    SET @result = '多頭懷抱線'
                    BREAK
                END
                ELSE IF ((@today_c - @yesterday_c) > 0.5 * (@yesterday_o - @yesterday_c) AND (@today_c < @yesterday_o AND @today_c > @yesterday_c))
                BEGIN
                    SET @return_date = @date
                    SET @result = '多頭插入線'
                    BREAK
                END
                ELSE IF (@today_c > @yesterday_o AND @today_o < @yesterday_c)
                BEGIN
                    SET @return_date = @date
                    SET @result = '多頭吞噬線'
                    BREAK
                END
            END
            --空頭各種線判斷 紅黑
            ELSE IF (@yesterday_type>0 AND @yesterday_type != 99)
            BEGIN
                IF (@yesterday_c>@today_o AND @yesterday_o<@today_c)
                BEGIN
                    SET @return_date = @date
                    SET @result = '空頭懷抱線'
                    BREAK
                END
                ELSE IF ((@yesterday_c - @today_c) > 0.5 * (@yesterday_c - @yesterday_o) AND (@today_c > @yesterday_o AND @today_c < @yesterday_c))
                BEGIN
                    SET @return_date = @date
                    SET @result = '空頭插入線'
                    BREAK
                END
                ELSE IF (@today_c < @yesterday_o AND @today_o > @yesterday_c)
                BEGIN
                    SET @return_date = @date
                    SET @result = '空頭吞噬線'
                    BREAK
                END
            END
        END
    END

    IF (@result = '99')
        SET @result = '無結果'

    CLOSE cur
    DEALLOCATE cur
END