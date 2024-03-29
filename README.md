# Basic usage

## Encoding

### Start with knowing nothing
Run and check for help
```
bash ./encode_ecm12.sh
```

### A typical scenario
* Create a folder named App_BUILDLABEL.
* Copy ECM executables into the folder
* Test it on classes C, D and E, all intra
```
bash ./encode_ecm12.sh -b BUILDLABEL -s ./sort/sort_list_CDE_AI.txt
```

## Decoding

### Start with knowing nothing
Run and check for help
```
bash ./decode.sh
```

## Collect results and gather them into a CSV file
Check out CollectAndUpload.sh
