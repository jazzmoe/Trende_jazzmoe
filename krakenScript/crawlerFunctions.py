# -*- coding: utf-8 -*-
"""
Created on Sat Jun 24 11:12:27 2017

@author: kNUt
"""

from bs4 import BeautifulSoup
import urllib.request


def crawlPrices():
      urls = ["https://coinmarketcap.com/currencies/byteball/", 
             "https://coinmarketcap.com/currencies/iota/",
	     "https://coinmarketcap.com/assets/numeraire/"]
      
      prices = []
      for url in urls:
            with urllib.request.urlopen(url) as response:
               html = response.read()
            
            soup = BeautifulSoup(html, "lxml")
            spans = soup.find_all('span', attrs={'id':'quote_price'})
            
            for span in spans:
                  tmp = span.text
                  prices.append(float(tmp[1:]))
            
      return prices