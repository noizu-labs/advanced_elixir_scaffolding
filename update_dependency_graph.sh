mix xref graph --format dot
mkdir -p doc/xref
mv xref_graph.dot doc/xref/overview.dot
dot -Tsvg doc/xref/overview.dot -o doc/xref/overview.svg
