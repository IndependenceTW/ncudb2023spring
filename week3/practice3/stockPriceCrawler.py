import requests
import json
import pymssql
import argparse
from fake_useragent import UserAgent

# 目標是爬取3260威剛上櫃公司(otc) 以及 2603大排長榮上市公司(tse)
# targets = [3260, 2603]
# types = ['otc', 'tse']

user = UserAgent()
url = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch={}_{}.tw&json=1&delay=0"
db_settings = {
    "host": "172.30.52.193",
    "user": "sa",
    "password": "255089",
    "database": "ncudb",
    "charset": "utf8"
}


def get_stock(type, target):
    response = requests.get(url.format(type, target), headers={
        'User-Agent': user.random
    })
    dict = json.loads(response.text)
    info = dict['msgArray'][0]
    stock = []
    stock.append(info['c'])  # 代號
    stock.append(info['d'])  # 日期
    stock.append(info['t'])  # 時間
    stock.append(float(info['v']) * 1000)  # 成交股數
    stock.append(0)  # 成交金額
    stock.append(info['o'])  # 開盤價
    stock.append(info['h'])  # 最高價
    stock.append(info['l'])  # 最低價
    stock.append(0 if info['z'] == '-' else float(info['z']))  # 收盤價
    stock.append(0 if info['z'] ==
                 '-' else float(info['z']) - float(info['y']))  # 漲跌價差
    stock.append(0)  # 成交筆數
    return stock


def insert_sql(stock):
    try:
        conn = pymssql.connect(**db_settings)
        command = "INSERT INTO [dbo].[realtime_stock_price] (stock_code, date, time, tv, t, o, h, l, c, d, v) VALUES(%s ,%s, %s, %d, %d, %s, %s, %s, %s, %s, %s)"
        cursor = conn.cursor()
        cursor.execute(command, (stock[0], stock[1], stock[2], stock[3], stock[4],
                       stock[5], stock[6], stock[7], stock[8], stock[9], stock[10]))
        conn.commit()
        conn.close()
    except Exception as e:
        print(e)


parser = argparse.ArgumentParser()
parser.add_argument('type', help="上市公司(tse)或是上櫃公司(otc)")
parser.add_argument('stock_id', help="欲搜尋台股的編號")
args = parser.parse_args()

stock = get_stock(args.type, args.stock_id)
insert_sql(stock)
