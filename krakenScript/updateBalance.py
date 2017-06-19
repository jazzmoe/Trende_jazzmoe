# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 19:36:26 2017

@author: kNUt
"""

import krakenex

k = krakenex.API()
k.load_key('kraken.key')
# get account balance
balance = k.query_private('Balance')

f = open('balance.csv', 'w')
f.write('Item' + '\t' + 'Quantity' + '\t' + 'Current Price\n')
for items in balance["result"].items():
      if items[0] == 'XETH':
            ticker = k.query_public('Ticker',{'pair': 'XETHZEUR', 'count' : '10'})
            price = float(ticker["result"]["XETHZEUR"]["c"][0])*float(items[1])
      elif items[0] == 'XXBT':
            ticker = k.query_public('Ticker',{'pair': 'XXBTZEUR', 'count' : '10'})
            price = float(ticker["result"]["XXBTZEUR"]["c"][0])*float(items[1])
      elif items[0] == 'ZEUR':
            price = float(items[1]) 
      f.write(items[0] + '\t' + '%.4f' % float(items[1]) + '\t\t' + '%.4f' % price + '\n')
f.close()