# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 19:36:26 2017

@author: kNUt
"""

#
import krakenex

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

f.write('\nTotal' + '\t' + 'X' + '\t' + '%.4f' % totalValue + '\n')
f.write('Invested Capital' + '\t' + 'X' + '\t' + '%.4f' % capitalStart + '\n')

# calculations
PL = totalValue - capitalStart
f.write('P&L' + '\t' + 'X' + '\t' + '%.4f' % PL + '\n')
PL_pct = PL/capitalStart
f.write('Return on Investment' + '\t' + 'X' + '\t' + '%.4f' % PL_pct + '\n')

f.close()

""" To do:
1. Trade history mit einbauen; 
2. Simple trade orders angeben
3. IOTA und Byteball hinzufügen
4. Simples trading script schreiben: In Echtzeit Preise ziehen und bestimmte trading rules festlegen
"""


