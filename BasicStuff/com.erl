

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
ProcNum =10,
segfile("./data.dat",ProcNum rem 3 ),
initProc(ProcNum,ProcNum),
     Msg =[1,88,99].
     %whereis('P_2') ! Msg.

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
    %io:format("~p~n",[Lines]),
    MyLists = [ lists:sublist(Lines, X, S) || X <- lists:seq(1,length(Lines),S) ],
    %io:format("~p~n", [MyLists] ),
    io:format("~p~n", [length(MyLists)]),
    %%io:format("~p~n",[lists:nth(2,MyLists)]),
    	
      for(1,length(MyLists), fun(Index) ->	    
     				    filewrite(string:concat("./seg/F_", integer_to_list(Index)),lists:nth(Index,MyLists))
	                           %io:format("~p has been written to ~p ~n", [FileName,string:concat("./seg/F_", integer_to_list(Index)) ])
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
	      FileName =string:concat("./seg/F_",integer_to_list(((Limit+1) rem N)+1)),
 	      %io:format("Reading frag from: ~p  ~n ",[FileName]),
              {ok, Binary} = file:read_file(FileName),
	      Lines = string:tokens(erlang:binary_to_list(Binary), "\n|,"),
	      put("Next",Limit+1),
	      put("Pre",Limit-1),
	      if
	      Limit == N -> erase("Next") , put("Next",0) ;
	      Limit == 0 -> erase("Pre"), put("Pre", N);
	      true -> Q=1
	      end,     
	      % io:format("in procc method ~n "),
		Next = get("Next"), erase("Next"),
		Pre = get("Pre") , erase("Pre"),
	       put("Neighbour",[Pre ,Next]),
		Data =[random:uniform(10) || _ <- lists:seq(1, 10)],
	       put("frag", Lines),
	       io:format("Neighbour are: ~p  ~n ",[get("Neighbour")]),
	       io:format("Keys: ~p  ~n ",[get("frag")]),
	       Newcount = Limit -1,
	       %threadoperation(get("frag"),get("Neighbour")),
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
     


initialise([Pidlist]) ->
	lists:foreach(fun(Pid) -> Pid ! initialise end, Pidlist).	       		      

threadoperation([Pids], Myvalue) ->
	receive 
		initialise ->	
			%io:format("Initialising ~p ~n",[self()]),
			put("min",[Myvalue]),
			put("max",[Myvalue]),
			threadoperation([Pids], Myvalue);
		{calculate,Function, Value} ->
	      		er_calculate ! {self(), Function, Myvalue, Value},
	      		lists:foreach(fun(Pid) -> Pid ! {calculate,Function,Myvalue} end, Pids),
	      		threadoperation([Pids],Myvalue);
		{update, Function, Value} ->
			% io:format("~p: Got updated value: ~p", [self(),Value]),
			 erase(Function),
			 put(Function, Value),
			 threadoperation([Pids], get(Function))		      	  
				     					
	end.


calculate() ->
	  
receive
	%start ->
	  %    io:format("Received start ~n");
	{Pid_proc, Function,Val1, Val2} ->
		%io:format(" Received message from ~p. Function is ~p. VLalues are ~p ~p ~n", [Pid_proc, Function, Val1, Val2]),
		case Function of 
	  	  min -> 
		     	 Min = erlang:min(Val1, Val2), 	 
			 io:format("Minimum value at ~p is ~p ~n", [Pid_proc, Min]),
			 Pid_proc ! {update, Function, [Min]};
	   	  max -> 
		        Max = erlang:max(Val1, Val2),
		        io:format("Maximum value at ~p is ~p ~n", [Pid_proc, Max]),
			Pid_proc ! {update, Function, Max}
		      
		  end,
		  
	calculate()
end.
     
     
     
    
    
    
