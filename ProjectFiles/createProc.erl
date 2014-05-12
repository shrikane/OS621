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
     NumNode = length(nodes())+1,
     Evaluation = (Limit rem NumNode),
	 NodeList = nodes(),
       	 FragId = (Limit rem Frag) +1,
       
	      Lines = getFrag(FragId),
	      if
	      Topology == 1  -> Route = getRoutingTable(N,Limit) ;
	      true -> Route = getRoutingTableMesh(N,Limit)
	      end,
	   
	   
	   if
	     Evaluation == 0  -> global:register_name(Processname ,spawn_link(gossip , threadoperation , [Route,Lines,FragId, Processname]));
	     true ->  global:register_name(Processname ,spawn_link( lists:nth( Evaluation , nodes()),gossip , threadoperation , [Route,Lines,FragId, Processname]))
     end,
    global:send( Processname , { initialise, Function}),
    io:format("Process ~p spawned ~n", [Processname]),		
     initProc(Limit-1,N,Topology,Function,Frag).
