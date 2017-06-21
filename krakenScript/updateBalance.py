# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 19:36:26 2017

@author: kNUt
"""

#
import krakenex
import datetime
import pandas as pd

###############################################################################       
# define update balance function
def updateBalance(k):
      currentValue = []
      tickerName = []
      totalValue = 0
      for items in balance["result"].items():
            if items[0] == 'XETH':
                  ticker = k.query_public('Ticker',{'pair': 'XETHZEUR', 'count' : '10'})
                  currentValue.append(float(ticker["result"]["XETHZEUR"]["a"][0])*float(items[1]))
                  tickerName.append('XETH')
                  totalValue += currentValue[-1]
            elif items[0] == 'XXBT':
                  ticker = k.query_public('Ticker',{'pair': 'XXBTZEUR', 'count' : '10'})
                  currentValue.append(float(ticker["result"]["XXBTZEUR"]["a"][0])*float(items[1]))
                  totalValue += currentValue[-1]
                  tickerName.append('XXBT')
            elif items[0] == 'ZEUR':
                  currentValue.append(float(items[1])) 
                  totalValue += currentValue[-1]
                  tickerName.append('ZEUR')
      
      balanceTable = {"Ticker" : tickerName,
                     "Value" : currentValue}
      balanceDf = pd.DataFrame(balanceTable)
      balanceDf = balanceDf[['Ticker', 'Value']]
      
      # profit and loss calculations
      PL = totalValue - capitalStart
      PL_pct = PL/capitalStart
      plTable = {"Ticker" : ["", "Capital Start", "Total", "PL", "PL%"],
                 "Value" : ["", capitalStart, totalValue, PL, str(round(100*PL_pct,2)) + '%']}
      plDf = pd.DataFrame(plTable)
      balanceDf = balanceDf.append(plDf)
      return balanceDf


###############################################################################  
## Main Part
# open API
k = krakenex.API()
# sucht automatisch im ordner nach dem key
k.load_key('kraken.key')
# get account balance
balance = k.query_private('Balance')

# open excel file to write to
ew = pd.ExcelWriter('tradeHistory.xlsx')

# total fiat investment in the beginning
fiatInvestment = 565
currentGBYTE = 0.11615008
currentIOT = 130.89

# BTC und ETH Wert vom 19.06.2017
capitalStart = 380.8477

# update Balance
balanceDf = updateBalance(k)
print(balanceDf)
balanceDf.to_excel(ew, sheet_name="Balance", index=False)


## get closed orders
orders = k.query_private("ClosedOrders")

orderPairs = ["ETHXBT", "ETHEUR", "XBTEUR"]

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
""" To do:
2. Simple trade orders angeben
3. IOTA und Byteball hinzufügen
4. Simples trading script schreiben: In Echtzeit Preise ziehen und bestimmte trading rules festlegen
"""


