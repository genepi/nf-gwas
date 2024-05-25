#!/bin/bash

mkdir -p experiments

/Users/lukfor/Development/git/nf-test/target/nf-test-0.8.4/nf-test test --csv experiments/baseline.times.txt

chunks=5
for i in $(seq 1 $chunks)
do
    echo "Run shard ${i}..."
    /Users/lukfor/Development/git/nf-test/target/nf-test-0.8.4/nf-test test --csv experiments/shard.${i}.none.txt --shard ${i}/${chunks} --shard-strategy "none"
    csvtk mutate2 -n shard  -e "${i}" experiments/shard.${i}.none.txt | csvtk mutate2 -n strategy  -e "'none'" > experiments/shard.${i}.none.final.txt

    /Users/lukfor/Development/git/nf-test/target/nf-test-0.8.4/nf-test test --csv experiments/shard.${i}.rr.txt --shard ${i}/${chunks} --shard-strategy "round-robin"
    csvtk mutate2 -n shard  -e "${i}" experiments/shard.${i}.rr.txt | csvtk mutate2 -n strategy  -e "'round-robin'" > experiments/shard.${i}.rr.final.txt


done

csvtk concat experiments/*.final.txt > experiments/shard.times.txt
