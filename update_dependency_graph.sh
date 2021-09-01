MIX_ENV=test mix xref graph --format dot
mkdir -p docs/xref
mv xref_graph.dot docs/xref/overview.dot
dot -Tsvg docs/xref/overview.dot -o docs/xref/overview.svg
dot -Tpng docs/xref/overview.dot -o docs/xref/overview.png
