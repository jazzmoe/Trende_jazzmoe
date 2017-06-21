# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 19:36:26 2017

@author: kNUt
"""

#
import krakenex
import datetime
import pandas as pd

# open API
k = krakenex.API()
# sucht automatisch im ordner nach dem key
k.load_key('kraken.key')
# get account balance
balance = k.query_private('Balance')

# total fiat investment in the beginning
fiatInvestment = 565
currentGBYTE = 0.11615008
currentIOT = 130.89

# BTC und ETH Wert vom 19.06.2017
capitalStart = 380.8477
totalValue = 0
# open csv file and permit writing in file
f = open('balance.csv', 'w')
f.write('Item' + '\t' + 'Quantity' + '\t' + 'Current Price\n')

for items in balance["result"].items():
      if items[0] == 'XETH':
            ticker = k.query_public('Ticker',{'pair': 'XETHZEUR', 'count' : '10'})
            currentValue = float(ticker["result"]["XETHZEUR"]["a"][0])*float(items[1])
            totalValue += currentValue
      elif items[0] == 'XXBT':
            ticker = k.query_public('Ticker',{'pair': 'XXBTZEUR', 'count' : '10'})
            currentValue = float(ticker["result"]["XXBTZEUR"]["a"][0])*float(items[1])
            totalValue += currentValue
      elif items[0] == 'ZEUR':
            currentValue = float(items[1]) 
            totalValue += currentValue
      f.write(items[0] + '\t' + '%.4f' % float(items[1]) + '\t' + '%.4f' % currentValue + '\n')

f.write('\nTotal' + '\t' + '%.4f' % totalValue + '\n')
f.write('Invested Capital' + '\t' + '%.4f' % capitalStart + '\n')

# calculations
PL = totalValue - capitalStart
f.write('P&L' + '\t' + '%.4f' % PL + '\n')
PL_pct = PL/capitalStart
f.write('Return on Investment' + '\t' + '%.4f' % PL_pct + '\n')

f.close()


## get closed orders
XBTNames = []
XBTPair = []
XBTVol= []
XBTCost = []
XBTPrice = []
XBTTime = []
XBTFee = []
BTCNames = []
BTCPair = []
BTCVol= []
BTCCost = []
BTCPrice = []
BTCTime = []
BTCFee = []
ETHNames = []
ETHPair = []
ETHVol= []
ETHCost = []
ETHPrice = []
ETHTime = []
ETHFee = []
orders = k.query_private("ClosedOrders")
for key, values in orders["result"]["closed"].items():
      pair = values["descr"]["pair"]
      if pair == "ETHXBT":
            BTCNames.append(key)
            BTCPair.append(pair)
            BTCPrice.append(values["price"])
            BTCCost.append(values["cost"])
            timeStr = datetime.datetime.fromtimestamp(values["closetm"]).strftime('%Y-%m-%d %H:%M:%S')
            BTCTime.append(timeStr)
            BTCFee.append(values["fee"])
            BTCVol.append(values["vol"])
      elif pair == "ETHEUR":
            ETHNames.append(key)
            ETHPair.append(pair)
            ETHPrice.append(values["price"])
            ETHCost.append(values["cost"])
            timeStr = datetime.datetime.fromtimestamp(values["closetm"]).strftime('%Y-%m-%d %H:%M:%S')
            ETHTime.append(timeStr)
            ETHFee.append(values["fee"])
            ETHVol.append(values["vol"])
      elif pair == "XBTEUR":
            XBTNames.append(key)
            XBTPair.append(pair)
            XBTPrice.append(values["price"])
            XBTCost.append(values["cost"])
            timeStr = datetime.datetime.fromtimestamp(values["closetm"]).strftime('%Y-%m-%d %H:%M:%S')
            XBTTime.append(timeStr)
            XBTFee.append(values["fee"])
            XBTVol.append(values["vol"])
            
# create a python dict
xbtTable = {"Time" : XBTTime, 
           'Pair' : XBTPair,
           'Vol' : XBTVol,
           'Cost' : XBTCost,
           'Price' : XBTPrice,
           'Name' : XBTNames}

ethTable = {"Time" : ETHTime, 
           'Pair' : ETHPair,
           'Vol' : ETHVol,
           'Cost' : ETHCost,
           'Price' : ETHPrice,
           'Name' : ETHNames}

btcTable = {"Time" : BTCTime, 
           'Pair' : BTCPair,
           'Vol' : BTCVol,
           'Cost' : BTCCost,
           'Price' : BTCPrice,
           'Name' : BTCNames}


# write table to excel file
ew = pd.ExcelWriter('tradeHistory.xlsx')
xbtDf = pd.DataFrame(xbtTable)
xbtDf = xbtDf[['Time', 'Pair', 'Vol', 'Cost', 'Price', 'Name']]
xbtDf.to_excel(ew, sheet_name='XBTEUR')

ethDf = pd.DataFrame(ethTable)
ethDf = ethDf[['Time', 'Pair', 'Vol', 'Cost', 'Price', 'Name']]
ethDf.to_excel(ew, sheet_name='ETHEUR')

btcDf = pd.DataFrame(btcTable)
btcDf = btcDf[['Time', 'Pair', 'Vol', 'Cost', 'Price', 'Name']]
btcDf.to_excel(ew, sheet_name='BTCETH')
ew.save() # don't forget to call save() or the excel file won't be created


""" To do:
2. Simple trade orders angeben
3. IOTA und Byteball hinzufügen
4. Simples trading script schreiben: In Echtzeit Preise ziehen und bestimmte trading rules festlegen
"""


