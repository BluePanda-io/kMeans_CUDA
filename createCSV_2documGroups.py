# Importing library
import csv
import random
from random import randint


def saveListCSV(list,data):
    # opening the csv file in 'w+' mode
    file = open(list, 'w+', newline ='')
    
    # writing the vectorsDocuments into the file
    with file:    
        write = csv.writer(file)
        write.writerows(data)




numDimsionsVector = 2
numDocuments = 100
numGroups = 4 # Groups on the Knn algorithm


vectorsDocuments = [] # The size is (numDocuments,numDimsionsVector)
groupGroundTruth = [] # The size is (numDocuments,1) -> and the possible values are (0,numGroups - 1)
initialVariableDocuments = [[numDimsionsVector],[numDocuments],[numGroups]] # [numDimsionsVector,numDocuments,numGroups]

for i in range(int(numDocuments/2)):
    # numbers range from 0
    integer_list = random.sample(range(0, 100), numDimsionsVector)
    # integer_list = random.sample(range(0, 30), numDimsionsVector)
    float_list = [x/5 for x in integer_list]

    vectorsDocuments.append(float_list)

    # groupGroundTruth.append([0])
    groupGroundTruth.append([randint(0,numGroups-1)])



for i in range(int(numDocuments/2)):
    # numbers range from 0
    integer_list = random.sample(range(0, 100), numDimsionsVector)
    # integer_list = random.sample(range(70, 100), numDimsionsVector)
    float_list = [x/5 for x in integer_list]

    vectorsDocuments.append(float_list)

    # groupGroundTruth.append([1])
    groupGroundTruth.append([randint(0,numGroups-1)])

# groupGroundTruth[4][0] = 1

print(vectorsDocuments)

print(groupGroundTruth)
  
  
saveListCSV('documents/vectorsDocuments.csv',vectorsDocuments)
saveListCSV('documents/groupGroundTruth.csv',groupGroundTruth)
saveListCSV('documents/initialVariableDocuments.csv',initialVariableDocuments)

