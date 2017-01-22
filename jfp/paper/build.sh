for i in $( ls *.lhs); do
    lhs2TeX --poly $i > ${i%.lhs}.tex
done
