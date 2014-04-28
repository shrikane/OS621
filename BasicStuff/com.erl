

-module(com).
-define(server_node, node@umbcCSEE).

%% ====================================================================
%% API functions
%% ====================================================================
-export([ start/0, initProc/2, process/2, segfile/2]).



%% ====================================================================
%% Internal functions
%% ====================================================================


start() ->
segfile("./data.dat",2),
initProc(5,5),
     Msg =[1,88,99],
     whereis('P_5') ! Msg.
	

%%  author: Yin Huang
%%  Input: 1. filename to be segmented for example: ""./data/data.dat"
%%         2. Size of the chunk (all equal) so the number of fragments = size of data / size of the chunk.
%%  Output: same size chunks of the original file written to ./seg/F_index
%%  Note:   output directory is hard coded as under ./seg so you need to mkdir seg under current directory 



for(Max, Max, F) ->
    [F(Max)];
for(I, Max,F) ->
    [F(I)|for(I+1,Max, F)].

segfile(FileName,S) ->
    {ok, Binary} = file:read_file(FileName),
    Lines = string:tokens(erlang:binary_to_list(Binary), "\n"),
    io:format("~p~n",[Lines]),
    MyLists = [ lists:sublist(Lines, X, S) || X <- lists:seq(1,length(Lines),S) ],
    io:format("~p~n", [MyLists] ),
    io:format("~p~n", [length(MyLists)]),
    %%io:format("~p~n",[lists:nth(2,MyLists)]),
    	
      for(1,length(MyLists), fun(Index) ->
     				    filewrite(string:concat("./seg/F_", integer_to_list(Index)),lists:nth(Index,MyLists)),
	                           io:format("~p has been written to ~p ~n", [FileName,string:concat("./seg/F_", integer_to_list(Index)) ])
					end
	).


filewrite(File, L) ->
   case file:open(File, [write]) of
      {ok, Device} ->
         lists:foreach(fun(Line) -> writeline(Device, Line) end, L),
         file:close(Device)
   end.
writeline(Device, Line) -> writeline(Device, Line, os:type()).

writeline(Device, Line, {win32,_}) -> io:fwrite(Device, "~s\r\n", [Line]);
writeline(Device, Line, _) -> io:fwrite(Device, "~s\n", [Line]).


%%  author: Shrinivas Kane
%%  Input: 1. Process ID number
%%         2. Number of process to be spawn


process(-1,5) ->
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
     
     
     
     
    
    
    
