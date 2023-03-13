target="./target.txt"

while read -a line;
do
    python stockPriceCrawler.py ${line[0]} ${line[1]}
done < $target
