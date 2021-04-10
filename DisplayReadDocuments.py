# Importing library
import csv
import random
from random import randint
import matplotlib.pyplot as plt



def saveListCSV(list,data):
    # opening the csv file in 'w+' mode
    file = open(list, 'w+', newline ='')
    
    # writing the vectorsDocuments into the file
    with file:    
        write = csv.writer(file)
        write.writerows(data)


def readListCSV(fileD,type):
    dataList = []

    with open(fileD, 'r') as file:
        reader = csv.reader(file)
        for row in reader:
            # print(row)
            # dataList = float(row)
            if (type=='flaot'):
                dataList.append([float(i) for i in row])
            else:
                dataList.append([int(float(i)) for i in row])
                # dataList.append(row)


                # dataList.append([int(i) for i in row])


    return(dataList)




  
vectorsDocuments = readListCSV('documents/vectorsDocuments.csv','float')
groupGroundTruth = readListCSV('documents/groupGroundTruth.csv','int')
initialVariableDocuments = readListCSV('documents/initialVariableDocuments.csv','int')


print(vectorsDocuments)
print(groupGroundTruth)
print(initialVariableDocuments)


# ------------------- Color for the Display --------------------
col =[]
for i in range(0, len(groupGroundTruth)):
    # print(groupGroundTruth[i])
    if groupGroundTruth[i][0]==0:
        col.append('blue')  
    elif groupGroundTruth[i][0]==1:
        col.append('red')  
    elif groupGroundTruth[i][0]==2:
        col.append('green')  
    elif groupGroundTruth[i][0]==3:
        col.append('yellow')  
    elif groupGroundTruth[i][0]==4:
        col.append('black')  
    elif groupGroundTruth[i][0]==5:
        col.append('pink')  
    else:
        col.append('magenta') 
print(col)
# ------------------- Color for the Display --------------------


# ------------------- display the vector ------------------
for i in range(len(vectorsDocuments)):
    plt.scatter(vectorsDocuments[i][0], vectorsDocuments[i][1], c = col[i])
    # plt.scatter(vectorsDocuments[i][0], vectorsDocuments[i][1], c = col[i], s = 10,linewidth = 0)
      
  
# plt.show()
plt.savefig('result_kMeans.png')
# ------------------- display the vector ------------------

