# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 19:36:26 2017

@author: kNUt
"""

import krakenex
import datetime
import pandas as pd
import crawlerFunctions as cf

###############################################################################       
# define update balance function
def updateBalance(k):
      
      balance = k.query_private('Balance')
      currentValue = []
      currentPrice = []
      currentQuantity = []
      tickerName = []
      totalValue = 0
      for items in balance["result"].items():
            if items[0] == 'ZEUR':
                  currentValue.append(float(items[1])) 
                  currentQuantity.append(float(items[1]))
                  currentPrice.append("")
                  totalValue += currentValue[-1]
                  tickerName.append('ZEUR')
            else:
                  pairName = items[0] + 'ZEUR'
                  ticker = k.query_public('Ticker',{'pair': pairName, 'count' : '10'})
                  currentValue.append(float(ticker["result"][pairName]["a"][0])*float(items[1]))
                  currentPrice.append(float(ticker["result"][pairName]["a"][0]))
                  currentQuantity.append(float(items[1]))
                  tickerName.append(items[0])
                  totalValue += currentValue[-1]

      othersPrices = cf.crawlPrices()
      tickerName.append("ByteBall")
      currentPrice.append(othersPrices[0])
      currentValue.append(othersPrices[0]*currentGBYTE*(1/1.12))
      currentQuantity.append(currentGBYTE)
      totalValue += currentValue[-1]
      
      tickerName.append("IOTA")
      currentPrice.append(othersPrices[1])
      currentValue.append(othersPrices[1]*currentIOT*(1/1.12))
      currentQuantity.append(currentIOT)
      totalValue += currentValue[-1]

      tickerName.append("Numeraire")
      currentPrice.append(othersPrices[2])
      currentValue.append(othersPrices[2]*currentNumeraire*(1/1.12))
      currentQuantity.append(currentNumeraire)
      totalValue += currentValue[-1]
      
      balanceTable = {"Ticker" : tickerName,
                     "Value" : currentValue,
                     "Price" : currentPrice,
                     "Quantity" : currentQuantity}
      balanceDf = pd.DataFrame(balanceTable)
      balanceDf = balanceDf[['Ticker', 'Value', 'Price', 'Quantity']]
      
      # profit and loss calculations
      PL = totalValue - capitalStart
      PL_pct = PL/capitalStart
      plTable = {"Ticker" : ["", "Fiat Investment", "Total", "PL", "PL%"],
                 "Value" : ["", capitalStart, totalValue, PL, str(round(100*PL_pct,2)) + '%'],
                 "Price" : ["", "", "", "", ""],
                 "Quantity" : ["", "", "", "", ""]}
      plDf = pd.DataFrame(plTable)
      plDf = plDf[['Ticker', 'Value', 'Price', 'Quantity']]
      balanceDf = balanceDf.append(plDf)
      return balanceDf

###############################################################################  
## Main Part
# open API
k = krakenex.API()
# sucht automatisch im ordner nach dem key
k.load_key('kraken.key')
# get account balance

# open excel file to write to
ew = pd.ExcelWriter('tradeHistory.xlsx')

# total fiat investment in the beginning
fiatInvestment = 2060
currentGBYTE = 0.11615008
currentIOT = 340
currentNumeraire = 0.83464286

# BTC und ETH Wert vom 19.06.2017 380.8477
# # +100 23.06.2017
# capitalStart = 480.8477
# including IOTA und GByte
capitalStart = 2060

# update Balance
balanceDf = updateBalance(k)
print(balanceDf)

#to excel
balanceDf.to_excel(ew, sheet_name="Balance", index=False)

## get closed orders
orders = k.query_private("ClosedOrders")

# REPLACE TO AUTOMATICE SCRIPT
orderPairs = ["ETHXBT", "ETHEUR", "XBTEUR", "XLTCEUR"]

for nn in range(len(orderPairs)):
      currentPair = orderPairs[nn]
      orderNames = []
      orderPair = []
      orderVol= []
      orderCost = []
      orderPrice = []
      orderTime = []
      orderFee = []
      for key, values in orders["result"]["closed"].items():
            pair = values["descr"]["pair"]
            if pair == currentPair:
                  orderNames.append(key)
                  orderPair.append(currentPair)
                  orderPrice.append(values["price"])
                  orderCost.append(values["cost"])
                  timeStr = datetime.datetime.fromtimestamp(values["closetm"]).strftime('%Y-%m-%d %H:%M:%S')
                  orderTime.append(timeStr)
                  orderFee.append(values["fee"])
                  orderVol.append(values["vol"])
            
      # create a python dict
      orderTable = {"Time" : orderTime, 
                 'Pair' : orderPair,
                 'Vol' : orderVol,
                 'Cost' : orderCost,
                 'Price' : orderPrice,
                 'Name' : orderNames}

      orderDf = pd.DataFrame(orderTable)
      orderDf = orderDf[['Time', 'Pair', 'Vol', 'Cost', 'Price', 'Name']]
      orderDf.to_excel(ew, sheet_name=currentPair, index=False)

ew.save() # don't forget to call save() or the excel file won't be created


###############################################################################
"""
4. Simples trading script schreiben: In Echtzeit Preise ziehen und bestimmte trading rules festlegen
"""


