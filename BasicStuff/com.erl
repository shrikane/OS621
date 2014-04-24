%% @author Shrinivas
%% @doc @todo Add description to com.


-module(com).
-define(server_node, node@umbcCSEE).

%% ====================================================================
%% API functions
%% ====================================================================
-export([ start/0, initProc/1, process/1]).



%% ====================================================================
%% Internal functions
%% ====================================================================


start() ->
initProc(5).


process(0) ->
    true;

process(Limit) ->
	       	       
	      % io:format("in procc method ~n "),
	       put("Neighbour",[Limit+1,Limit-1]),
	       put("frag", [random:uniform(20) ,random:uniform(20)]),
	       io:format("Neighbour are: ~p  ~n ",[get("Neighbour")]),
	       io:format("NKeys: ~p  ~n ",[get("frag")]),
	       Newcount = Limit -1,
	      % io:format(" NewCount: ~p ~n", [Newcount]),
	       initProc(Newcount).
	 %end.      


initProc(0) -> true;

initProc(Limit) ->  
    % io:format("Limit is ~p ~n ", [Limit]),
     Processname = list_to_atom(string:concat( "p_" ,integer_to_list(Limit))),
     register(Processname ,spawn_link(com , process , [Limit])),
     io:format("Forked ~p ~n",[Processname]).
     
     
     
     
    
    
    
