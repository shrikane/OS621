-module(createProc).
-export([getFrag/1,initProc/5]).
-import(network,[getRoutingTable/2,getRoutingTableMesh/2,listAppneder/2]).

getFrag(FragId) ->
 FileName =string:concat("./seg/F_",integer_to_list(FragId)),
	       io:format("Frag Id: ~p ~n", [FragId]),
 	      %io:format("Reading frag from: ~p  ~n ",[FileName]),
              {ok, Binary} = file:read_file(FileName),
	     
	      Lines1 = string:tokens(erlang:binary_to_list(Binary), "\n|,"),
		Lines = lists:map(fun(X) -> {Int, _} = string:to_float(X), Int end, Lines1).


initialise(Pidlist, Function) ->
	lists:foreach(fun(Pid) -> global:send(Pid, {initialise, Function}) end, Pidlist).	       		      

startprocessing(Pidlist, Function) ->
	lists:foreach(fun(Pid) ->
		global:send( Pid, {timer, Function}) end, Pidlist).




initProc(-1,N,Topology,Function,Frag) -> 
%io:format("NP_id: ~p  ~n ",[]),
Pids =listAppneder(N,[]),
startprocessing(Pids, Function);


initProc(Limit,N,Topology,Function,Frag) ->  
    
     Processname = list_to_atom(string:concat( "P_" ,integer_to_list(Limit))),
     put("registeredName", Processname),
     io:format("name: ~p~n", [get("registeredName")]), 
     NumNode = length(nodes())+1,
     Evaluation = (Limit rem NumNode),
	 NodeList = nodes(),
	 	io:format("Number of Nodes connected to me ~p ~n ", [NumNode]),
	 	io:format(" Nodes connected to me ~p ~n ", [NodeList]),
       FragId = (Limit rem Frag) +1,
       
	      Lines = getFrag(FragId),
	      %io:format("Data ~p ~n ", [Lines]),
	      if
	      Topology == 1  -> Route = getRoutingTable(N,Limit) ;
	      true -> Route = getRoutingTableMesh(N,Limit)
	      end,
	   %io:format("Adding route is ~p ~n ", [Route]), 
	   
	   
	   if
	     Evaluation == 0  -> global:register_name(Processname ,spawn_link(gossip , threadoperation , [Route,Lines,FragId, Processname]));
	     true ->  global:register_name(Processname ,spawn_link( lists:nth( Evaluation , nodes()),gossip , threadoperation , [Route,Lines,FragId, Processname]))
     end,
     %register(Processname ,spawn_link(com , threadoperation , [Route,Lines,FragId])),
    global:send( Processname , { initialise, Function}),
     initProc(Limit-1,N,Topology,Function,Frag).
