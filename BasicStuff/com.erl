%% @author Shrinivas
%% @doc @todo Add description to com.


-module(com).
-define(server_node, node@umbcCSEE).

%% ====================================================================
%% API functions
%% ====================================================================
-export([ start/0, initProc/2, process/2]).



%% ====================================================================
%% Internal functions
%% ====================================================================


start() ->
initProc(5,5),
     Msg =[1,88,99],
     whereis('P_5') ! Msg.



process(0,5) ->
    true;

process(Limit,N) ->
	       	       
	      % io:format("in procc method ~n "),
	       put("Neighbour",[(Limit+1) rem N ,(Limit-1) rem N]),
	       put("frag", [random:uniform(20) ,random:uniform(20),Limit]),
	       io:format("Neighbour are: ~p  ~n ",[get("Neighbour")]),
	       io:format("NKeys: ~p  ~n ",[get("frag")]),
	       Newcount = Limit -1,
	      % io:format(" NewCount: ~p ~n", [Newcount]),
	       initProc(Newcount,N),
	 %end. 
		
	 receive 
	Msg ->
	  io:format("Keys in rec: ~p  ~n ",[get("frag")])
    end.


initProc(-1,N) -> 
%io:format("NP_id: ~p  ~n ",[]),
true;

initProc(Limit,N) ->  
    % io:format("Limit is ~p ~n ", [Limit]),
     Processname = list_to_atom(string:concat( "P_" ,integer_to_list(Limit))),
     register(Processname ,spawn_link(com , process , [Limit,N])),

io:format("Forked ~p ~n",[Processname]).
     
     
     
     
    
    
    
