-module(network).
-export([getRoutingTable/2,getRoutingTableMesh/2,listAppneder/2]).


%%  author: Shrinivas Kane
%%  N Number of nodes 


getRoutingTable(Max,N) ->
		erase("Next"),
		erase("Pre"),
   	   %io:format("Next: ~p ~n", [list_to_atom(string:concat( "P_" ,integer_to_list(N+1)))]),
 	   %io:format("Pre: ~p ~n", [list_to_atom(string:concat( "P_" ,integer_to_list(N-1)))]),
	     put("Next",list_to_atom(string:concat( "P_" ,integer_to_list(N+1)))),
	     put("Pre",list_to_atom(string:concat( "P_" ,integer_to_list(N-1)))),
	      if
	      Max == N -> erase("Next") , put("Next",list_to_atom(string:concat( "P_" ,integer_to_list(0)))) ;
	      N == 0 -> erase("Pre"), put("Pre", list_to_atom(string:concat( "P_" ,integer_to_list(N))));
	      true -> Q=1
	      end,     
	 Route = [get("Pre"),get("Next")].

listAppneder(0,Route) ->
lists:append(Route, [list_to_atom(string:concat( "P_" ,integer_to_list(0)))]);

listAppneder(N,Route) ->
Route1 = lists:append(Route, [list_to_atom(string:concat( "P_" ,integer_to_list(N)))]),
listAppneder(N-1,Route1).

getRoutingTableMesh(Max,N) ->
X = listAppneder(Max,[]),
X1 = lists:delete(list_to_atom(string:concat( "P_" ,integer_to_list(N))), X).
%io:format("Route: ~w ~n", [X1]).
