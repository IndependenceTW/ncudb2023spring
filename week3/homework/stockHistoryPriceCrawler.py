import pymssql
from FinMind.data import DataLoader

login_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJkYXRlIjoiMjAyMy0wMy0xMSAxODo0OTo0NSIsInVzZXJfaWQiOiJJbmRlcGVuZGVuY2VUVyIsImlwIjoiMjE4LjE3Mi45Ni4xNTMifQ.Qw-DikQzpdDHt4MSnyr8BdFLueUtKVZTxDZjAW1-0sk"
db_settings = {
    "host": "172.30.52.193",
    "user": "sa",
    "password": "255089",
    "database": "ncudb",
    "charset": "utf8"
}


def get_taiwan50_stock():
    stocks = []
    command = "SELECT stock_code FROM ncudb.dbo.stock_info WHERE isTaiwan50 = 1"
    conn = pymssql.connect(**db_settings)
    cursor = conn.cursor()
    cursor.execute(command)
    for row in cursor:
        stocks.append(row[0])
    conn.close()
    return stocks


def insert_sql(data):
    query = "INSERT INTO [dbo].[stock_price] (date, stock_code, tv, t, o, h, l, c, d, v) VALUES(%s, %s, %d, %d, %s, %s, %s, %s, %s, %s)"
    try:
        conn = pymssql.connect(**db_settings)
        cursor = conn.cursor()
        cursor.execute(query, (data[0], data[1], data[2].item(), data[3].item(), data[4].item(
        ), data[5].item(), data[6].item(), data[7].item(), data[8].item(), data[9].item()))
        conn.commit()
        conn.close()
    except Exception as e:
        print(e)


taiwan50 = get_taiwan50_stock()
api = DataLoader()
api.login_by_token(login_token)
for stock in taiwan50:
    df = api.taiwan_stock_daily(
        stock_id=stock, start_date="2021-01-01", end_date="2023-03-11")
    print("get the stock {}".format(stock))
    for i in range(0, df.shape[0]):
        data = list(df.iloc[i])
        insert_sql(data)
    print("finish stock id {}".format(stock))
print("finish all")

