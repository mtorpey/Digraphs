#############################################################################
##
#W  oper.gi
#Y  Copyright (C) 2014                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# graph algorithms

#JDM this is incomplete

InstallMethod(QuotientDigraph, "for a digraph and a list", 
[IsMultiDigraph and HasAdjacencies, IsHomogeneousList],
function(graph, verts)
  local nr, new_nr, adj, i, j;
  
  nr := NrVertices(graph);

  if (IsRange(verts) and not (IsPosInt(verts[1]) and verts[1] <= nr and
    verts[Length(verts)] <= nr)) 
    or ForAny(verts, x-> not IsPosInt(x) or x > nr) then 
    Error("Digraphs: QuotientDigraph: usage,\n ", 
      "the 2nd argument <verts> must consist of vertices of the 1st", 
      "argument <graph>,\n");
  fi;
  
  
  new_nr := Length(verts);
  adj := Adjacencies(graph);

  for i in Vertices(graph) do 
    for j in adj[i] do 
    od;
  od;

  return fail;
end)

InstallDigraphMethod(DigraphReverse, "for a digraph with source",
[IsDigraph and HasSource], MultiDigraphReverse);

InstallMethod(MultiDigraphReverse, "for a multidigraph with source",
[IsMultiDigraph and HasSource],
function(graph)
  local source, range;

    source := ShallowCopy(Range(graph));
    range := Permuted(Source(graph), Sortex(source));
  
    return MultiDigraphNC(rec( source:=source, 
                               range:=range,
                               nrvertices:=NrVertices(graph)));
end);

InstallMethod(MultiDigraphReverse, "for a multidigraph with adjacencies",
[IsMultiDigraph and HasAdjacencies],
function(graph)
  local old, new, i, j;

  old := Adjacencies(graph);
  new := List(Vertices(graph), x -> []);

  for i in Vertices(graph) do 
    for j in old[i] do 
      Add(new[j], i);
    od;
  od;

  return MultiDigraphNC(new);
end);

InstallMethod(MultiDigraphRemoveLoops, "for a multidigraph with source",
[IsMultiDigraph and HasSource],
function(graph)
  local source, range, newsource, newrange, nr, i;

  source := Source(graph);
  range := Range(graph);

  newsource := [];
  newrange := [];
  nr := 0;

  for i in [ 1 .. Length(source) ] do
    if range[i] <> source[i] then
      nr := nr + 1;
      newrange[nr] := range[i];
      newsource[nr] := source[i];
    fi;
  od;

  return MultiDigraphNC(rec(source:=newsource, 
                            range:=newrange,
                            nrvertices:=NrVertices(graph)));
end);

InstallMethod(MultiDigraphRemoveLoops, "for a multigraph with adjacencies",
[IsMultiDigraph and HasAdjacencies],
function(graph)
  local old, new, nr, i, j;
  
  old := Adjacencies(graph);
  new := [];

  for i in Vertices(graph) do 
    new[i] := []; 
    nr := 0;
    for j in old[i] do 
      if i <> j then 
        nr := nr + 1;
        new[i][nr]:= j;
      fi;
    od;
  od;

  return MultiDigraphNC(new);
end);

InstallMethod(MultiDigraphRemoveEdges, "for a multidigraph and a list",
[IsMultiDigraph, IsList],
function(graph, edges)
  local range, vertices, source, newsource, newrange, i;

  if Length(edges) > 0 and IsPosInt(edges[1]) then # remove edges by index
    edges := Difference( [ 1 .. Length(Source(graph)) ], edges );

    return MultiDigraphNC(rec(source := Source(graph){edges},
                              range := Range(graph){edges},
                              nrvertices := NrVertices(graph)));
  else
    source := Source(graph);;
    range := Range(graph);;
    newsource := [ ];
    newrange := [ ];

    for i in [ 1 .. Length(source) ] do
      if not [ source[i], range[i] ] in edges then
        Add(newrange, range[i]);
        Add(newsource, source[i]);
      fi;
    od;

    return MultiDigraphNC(rec(source:=newsource, 
                              range:=newrange,
                              nrvertices:=NrVertices(graph)));
  fi;
end);

InstallMethod(MultiDigraphRelabel, "for a multidigraph with adjacencies and perm",
[IsMultiDigraph and HasAdjacencies, IsPerm],
function(graph, perm)
  local adj;

  if ForAny(Vertices(graph), i-> i^perm > NrVertices(graph)) then
    Error("usage: the 2nd argument <perm> must permute ",
    "the vertices of the 1st argument <graph>,");
    return;
  fi;
  
  adj := Permuted(Adjacencies(graph), perm);
  Apply(adj, x-> OnTuples(x, perm));

  return MultiDigraphNC(adj);
end);

InstallMethod(MultiDigraphRelabel, "for a multidigraph and perm",
[IsMultiDigraph, IsPerm],
function(graph, perm)

  if ForAny(Vertices(graph), i-> i^perm > NrVertices(graph)) then
    Error("usage: the 2nd argument <perm> must permute ",
    "the vertices of the 1st argument <graph>,");
    return;
  fi;
  return MultiDigraphNC(rec(source := ShallowCopy(OnTuples(Source(graph), perm)),
                            range:= ShallowCopy(OnTuples(Range(graph), perm)),
                            nrvertices:=NrVertices(graph)));
end);

InstallMethod(DigraphFloydWarshall, "for a multidigraph",
[IsMultiDigraph],
function(graph)
  local dist, i, j, k, n, m;

  # Firstly assuming no multiple edges or loops. Will be easy to include.
  # Also not dealing with graph weightings.
  # Need discussions on suitability of data structures, etc

  n:=NrVertices(graph);
  m:=Length(Edges(graph));
  dist:=List([1..n],x->List([1..n],x->infinity));

  for i in [1..n] do
    dist[i][i]:=0;
  od;

  for i in [1..m] do
    dist[Source(graph)[i]][Range(graph)[i]]:=1;
  od;

  for k in [1..n] do
    for i in [1..n] do
      for j in [1..n] do
        if dist[i][k] <> infinity and dist[k][j] <> infinity 
         and dist[i][j] > dist[i][k] + dist[k][j] then
          dist[i][j]:= dist[i][k] + dist[k][j];
        fi;
      od;
    od;
  od;

  return dist;
end);

# returns the vertices (i.e. numbers) of <digraph> ordered so that there are no
# edges from <out[j]> to <out[i]> for all <i> greater than <j>.

InstallMethod(DigraphReflexiveTransitiveClosure, "for a digraph", [IsDigraph],
function(graph)
  local sorted, vertices, n, adj, out, trans, mat, flip, v, u, w;

  vertices := Vertices(graph);
  n := Length(vertices);
  adj := Adjacencies(graph);
  sorted := DigraphTopologicalSort(graph);

  if sorted <> fail then # Easier method for acyclic graphs (loops allowed)
    out := EmptyPlist(n);
    trans := EmptyPlist(n);

    for v in sorted do
      trans[v] := BlistList(vertices, [v]);
      for u in adj[v] do
        trans[v] := UnionBlist(trans[v], trans[u]);
      od;
      out[v] := ListBlist(vertices, trans[v]);
    od;

    out := DigraphNC(out);
    return out;
  else # Non-acyclic method
    mat := List( vertices, x -> List( vertices, y -> infinity ) ); 

    for v in [ 1 .. n ] do # Make graph reflexive
      mat[v][v] := 1;
    od;

    for v in vertices do # Record edges
      for u in adj[v] do
        mat[v][u] := 1;
      od;
    od;

    for w in vertices do # Variation of Floyd Warshall
      for u in vertices do
        for v in vertices do
          if mat[u][w] <> infinity and mat[w][v] <> infinity then
            mat[u][v] := 1;
          fi;
        od;
      od;
    od;

    flip:=function(x)
      if x = infinity then
        return 0;
      else
        return 1;
      fi;
    end;

    mat := List( mat, x -> List( x, flip ) ); # Create adjacency matrix
    out := DigraphByAdjacencyMatrix(mat);

    return out;
  fi;
end);

# JDM: requires a method for non-acyclic graphs

InstallMethod(DigraphTransitiveClosure, "for a digraph",
[IsDigraph],
function(graph)
  local sorted, vertices, n, adj, out, trans, reflex, mat, flip, v, u, w;

  vertices := Vertices(graph);
  n := Length(vertices);
  adj := Adjacencies(graph);
  sorted := DigraphTopologicalSort(graph);

  if sorted <> fail then # Easier method for acyclic graphs (loops allowed)
    out := EmptyPlist(n);
    trans := EmptyPlist(n);

    for v in sorted do
      trans[v] := BlistList( vertices, [v]);
      reflex := false;
      for u in adj[v] do
        trans[v] := UnionBlist(trans[v], trans[u]);
        if u = v then
          reflex := true;
        fi;
      od;
      if not reflex then
        trans[v][v] := false;
      fi;
      out[v] := ListBlist(vertices, trans[v]);
      trans[v][v] := true;
    od;

    out := DigraphNC(out);
    SetIsDigraph(out, true);
    return out;
  else # Non-acyclic method

    mat := List( vertices, x -> List( vertices, y -> infinity ) ); 
    reflex := [ 1 .. n ] * 0;
    
    for v in vertices do # Assume graph reflexive for now
      mat[v][v] := 1;
    od;

    for v in vertices do # Record edges and remember loops
      for u in adj[v] do
        mat[v][u] := 1;
        if u = v then
          reflex[v] := 1;
        fi;
      od;
    od;

    for w in vertices do # Variation of Floyd Warshall
      for u in vertices do
        for v in vertices do
          if mat[u][w] <> infinity and mat[w][v] <> infinity then
            mat[u][v] := 1;
          fi;
        od;
      od;
    od;

    flip:=function(x)
      if x = infinity then
        return 0;
      else
        return 1;
      fi;
    end;

    mat := List( mat, x -> List( x, flip ) ); # Create adjacency matrix
    for v in vertices do # Only include original loops
      mat[v][v] := reflex[v]; 
    od;
    out := DigraphByAdjacencyMatrix(mat);
    SetIsDigraph(out, true);
    return out;
  fi;
end);

