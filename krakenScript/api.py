import time
import krakenex
import matplotlib.pyplot as plt


k = krakenex.API()
#k.load_key('kraken.key')

pairName = 'XXBTZEUR'

# let the program run for X seconds ('totalTime')
totalTime = 5*60
# check the price every X seconds ('samplingRate')
samplingRate = 5
# if price falls by fallPerc or rises by risePerc (ín %)
# do something
fallPerc = 0.15
risePerc = 0.15
# Window size for moving average
smaWindow = 5

lastList = []
sma = []
#plt.ion()
fig=plt.figure()

#time.sleep(samplingRate)
# Run loop for 'totalTime' seconds and get every 'samplingRate'
# seconds the 'last trade' for 'pairName'
for nn in range(int(totalTime/samplingRate)):
	ticker = k.query_public('Ticker',{'pair': pairName, 'count' : '10'})
	lastList.append(float(ticker["result"][pairName]["c"][0]))
	if nn > 1:
		if lastList[nn] > (1+0.01*risePerc)*lastList[nn-1]:
			print('%.4f' % lastList[nn] + ' --- BUY!')
		elif lastList[nn] < (1-0.01*fallPerc)*lastList[nn-1]:
			print('%.4f' % lastList[nn] + ' --- SELL!')
		else:
			print('%.4f' % lastList[nn] + ' --- ' + '%.4f' % (lastList[nn]-lastList[nn-1]))

	# sma = last price until enoug data points are gathered
	if nn <= smaWindow:
		sma.append(lastList[nn])

	# start plotting and calculating sma - doesn't work yet on windows machines
#	if nn > smaWindow:
#		plt.close()
#		sma.append(sum(lastList[nn-smaWindow:nn])/smaWindow)
#		plt.plot(lastList)
#		plt.plot(sma)
#		plt.title(pairName)
#		plt.ylabel('Euro')
#		plt.xlabel('Time')
#		plt.legend(['LAST', 'SMA'])
#		plt.show()
#		plt.pause(0.05)

	time.sleep(samplingRate)

print('\n\n')
