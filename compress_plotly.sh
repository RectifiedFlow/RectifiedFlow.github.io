# For assets/plotly/*.html
for f in $(find assets/plotly -name '*.html'); do
    echo "Compressing $f"
    sed -E -i 's/([0-9]+\.[0-9]{3})[0-9]+/\1/g' $f
done