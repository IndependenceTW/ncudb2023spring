import pymssql
import pandas as pd
import numpy as np
import mplfinance as mpf
from collections import defaultdict

def connect_sql():
    db_settings = {
        "host": "172.30.52.193",
        "port": 1433,
        "user": "sa",
        "password": "255089",
        "database": "ncudb",
        "charset": "utf8"
    }
    conn = pymssql.connect(**db_settings)
    return conn

def get_data(company, start, end, cursor):
    command = f"""SELECT [date],[o],[h],[l],[c],[v],[MA5],[MA10]
            FROM [dbo].[stock_price]
            WHERE [stock_code] = {company} AND date > '{start}' AND date < '{end}'"""
    cursor.execute(command)

    arr = []
    row = cursor.fetchone()
    while row:
        arr.append(row)
        row = cursor.fetchone()
    
    arr_df = pd.DataFrame(arr)
    arr_df['Date'] = pd.to_datetime(arr_df[0])
    arr_df = arr_df.sort_values(by="Date")
    arr_df = arr_df.drop(columns=[0])
    arr_df.set_index("Date", inplace=True)

    arr_df.columns = ['Open', 'High', 'Low', 'Close', 'Volume', 'MA5', 'MA10']

    return arr_df

def get_turning_wave(company, start, end, cursor):
    command = f"""select end_date, end_date_price, trend
                from find_trend('{company}')
                WHERE end_date > '{start}' AND end_date < '{end}'
                ORDER BY end_date ASC
                """
    cursor.execute(command)

    arr = []
    row = cursor.fetchone()  
    while row:
        arr.append(row)
        row = cursor.fetchone()
    
    df = pd.DataFrame(arr)
    df.columns = ['date', 'close_price', 'trend']
    df.loc[:, 'date'] = pd.to_datetime(df['date'])
    
    df_result = pd.DataFrame()

    cur_trend = 0
    for idx in range(df['date'].size - 1, 0, -1):
        if df.loc[idx, 'trend'] != 0:
            cur_trend = df.loc[idx, 'trend']
            break

    cur_max_min = 0
    cur_start_day = np.nan
    for idx in range(df['date'].size - 1, -1, -1):
        if (df.loc[idx, 'trend'] != 0 and df.loc[idx, 'trend'] != cur_trend) or idx == 0:
            df_tmp = pd.DataFrame([[cur_start_day, np.nan, cur_max_min, cur_trend]],
                   columns=['start_day', 'end_day', 'close_price', 'trend'])
            df_result = pd.concat([df_tmp, df_result])
            cur_trend = df.loc[idx, 'trend']
            cur_max_min = 0
        
        if cur_trend == 1:
            if df.loc[idx, 'close_price'] > cur_max_min:
                cur_max_min = df.loc[idx, 'close_price']
                cur_start_day = df.loc[idx, 'date']
        else:
            if df.loc[idx, 'close_price'] < cur_max_min or cur_max_min == 0:
                cur_max_min = df.loc[idx, 'close_price']
                cur_start_day = df.loc[idx, 'date']
    df_result.reset_index(drop=True, inplace=True)
    df_result['end_day'] = df_result['start_day'].shift()
    df_result.loc[0, 'end_day'] = df.loc[0, 'date']
    
    return df_result

def find_patterns(min_max):
    patterns = defaultdict(list)

    for i in range(5, len(min_max)):
        window = min_max.iloc[i-5:i]
        if ((window.iloc[-1]['start_day'] - window.iloc[0]['start_day']).days > 100):
            continue
        a, b, c, d, e = window['close_price'].iloc[0:5]

        if b < c and d < c and abs(b - d) <= np.mean([b, d]) * 0.02 and a >= c:
            patterns['w'].append(window.index)

    for i in range(5, len(min_max)):
        window = min_max.iloc[i-5:i]
        if ((window.iloc[-1]['start_day'] - window.iloc[0]['start_day']).days > 100):
            continue

        a, b, c, d, e = window['close_price'].iloc[0:5]

        if b > c and d > c and abs(b - d) <= np.mean([b, d]) * 0.02 and a <= c:
            patterns['m'].append(window.index)

    return patterns

def prepare_plot_data(df, patterns, type, turning_wave, result):

    if len(patterns[type]) == 0:
        result[type] = {}
        result[type]['turning_points'] = []
        result[type]['datepairs'] = []
        result[type]['intervals'] = []
        result[type]['necklines'] = []
        return
    
    indicesList = []
    for indices in patterns[type]:
        indicesList.append(indices)

    turning_points = []
    date = df.index.date
    for i in range(len(date)):
        if str(date[i]) in turning_wave.loc[indicesList, 'start_day'].to_string():
            turning_points.append(df['Close'][i])
        else:
            turning_points.append(np.nan)

    datepairs = []
    dot_amount = patterns[type][0].size
    for indices in patterns[type]:
        for j in range(0, dot_amount-1):
            datepairs.append((turning_wave.loc[indices[j], 'start_day'], turning_wave.loc[indices[j+1], 'start_day']))

    intervals = []
    necklines = []
    for indices in patterns[type]:
        start_day = turning_wave.loc[indices[0], 'start_day']
        end_day = turning_wave.loc[indices[-1], 'start_day']
        intervals.append(start_day)
        intervals.append(end_day)

        if type == 'w' or type == 'm':
            price = turning_wave.loc[indices[2], 'close_price']
            necklines.append([(start_day, price), (end_day, price)])

    result[type] = {}
    result[type]['turning_points'] = turning_points
    result[type]['datepairs'] = datepairs
    result[type]['intervals'] = intervals
    result[type]['necklines'] = necklines

def plot_pattern(type, df, plot_data, datepairs_turning_wave):
    if len(plot_data[type]['turning_points']) == 0:
        mpf.plot(df, type='candle', style='yahoo', mav = (5), volume = True, figsize=(100,30),
                    tlines = [dict(tlines=datepairs_turning_wave, tline_use='close', colors='b', linewidths=5, alpha=0.7)])
        mpf.show
        return
    
    apd = [mpf.make_addplot(plot_data[type]['turning_points'], type='scatter', markersize=200, marker='^', color='aqua')]
    mpf.plot(df, type='candle', style='yahoo', mav = (5), volume = True, addplot = apd, figsize=(100,30),
                        tlines = [dict(tlines=datepairs_turning_wave, tline_use='close', colors='b', linewidths=5, alpha=0.7),
                            dict(tlines=plot_data[type]['datepairs'], tline_use='close', colors='r', linewidths=5, alpha=0.7)],
                        vlines = dict(vlines=plot_data[type]['intervals'], colors='c'),
                        alines = dict(alines=plot_data[type]['necklines'], colors='orange'))
    mpf.show

def main():
    conn = connect_sql()
    cursor = conn.cursor()

    company = '2330'
    day_start = '20210101'
    day_end = '20220228'

    #0522
    df = get_data(company, day_start, day_end, cursor)
    turning_wave = get_turning_wave(company, day_start, day_end, cursor)
    datepairs_turning_wave = [(d1, d2) for d1, d2 in zip(turning_wave['end_day'], turning_wave['start_day'])]

    '''
    輸出轉折波
    mpf.plot(df, type='candle', style='yahoo', mav = (5), volume = True, figsize=(100,30),
                 tlines = [dict(tlines=datepairs_turning_wave, tline_use='close', colors='b', linewidths=5, alpha=0.7)])
    mpf.show
    '''

    #0529
    patterns = find_patterns(turning_wave)
    #print(f'patterns["M"]: {patterns["M"]}')
    #print(patterns)

    plot_data = {} # note that dictionary is mutable
    prepare_plot_data(df, patterns, 'W', turning_wave, plot_data)
    prepare_plot_data(df, patterns, 'M', turning_wave, plot_data)
    # print(plot_data['W'])

if __name__ == '__main__':
    main()