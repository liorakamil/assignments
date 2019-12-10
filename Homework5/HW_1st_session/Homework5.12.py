#json to python
import json
with open("/Users/liorakamil/python/PycharmProjects/HW_1st_session/hw.json") as json_file:
    data = json.load(json_file)
    print("data: {}".format(data))

#arrange bucket for grouping
    buckets = data["buckets"]
    buckets.sort()
    buckets.insert(0, 0)
    people = data["ppl_ages"]
    print(people)
    max_age = max(people.values()) + 1
    print(max_age)
    buckets.append(max_age)
    print("buckets: {}".format(buckets))

#make ranges from bucket
    age_bucket = len(buckets) - 1
    print(age_bucket)

    sublist_in_bucket = []
    for i in range(0, age_bucket):
        sublist_in_bucket.append([])
    print(sublist_in_bucket)

#organize people by bucket ranges
    for name, age in people.items():
        for i in range(0, age_bucket):
            if age < buckets[i + 1]:
                sublist_in_bucket[i].append(name)
                break
    print(sublist_in_bucket)

#ranges with range names
    results = dict()
    for i in range(0, age_bucket):
        category = str((buckets[i])+1) + '-' + str(buckets[i+1])
        results[category] = sublist_in_bucket[i]
    print(results)


#from python/dict to yaml
import yaml
dictfile = {'1-11': ['Dana', 'Danail'], '12-20': ['Danger'], '21-25': ['Daneel', 'Daniele', 'Daniil', 'Dantes'], '26-40': ['Dandre', 'Dangelo', 'Danial', 'Danilo', 'Danner', 'Dannin'], '41-103': ['Dan', 'Dane', 'Danell', 'Danian', 'Daniel', 'Danielius', 'Danijel', 'Daniyal', 'Dannie', 'Danny', 'Dante', 'Danuel', 'Dănuț', 'Danyal', 'Danyl']}

with open(r'/Users/liorakamil/python/PycharmProjects/HW_1st_session/dictfile.yaml', 'w') as file:
    documents = yaml.dump(dictfile, file)









