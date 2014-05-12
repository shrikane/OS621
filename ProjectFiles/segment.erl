-module(segment).
-export ([segfile/2]).
%%  author: Yin Huang
%%  Input: 1. filename to be segmented for example: ""./data/data.dat"
%%         2. Size of the chunk (all equal) so the number of fragments = size of data / size of the chunk.
%%  Output: same size chunks of the original file written to ./seg/F_index
%%  Note:   output directory is hard coded as under ./seg so you need to mkdir seg under current directory 



for(Max, Max, F) ->
    [F(Max)];
for(I, Max,F) ->
    [F(I)|for(I+1,Max, F)].

segfile(FileName,N) ->
    {ok, Binary} = file:read_file(FileName),
    Lines = string:tokens(erlang:binary_to_list(Binary), "\n"),
    %io:format("~p~n",[Lines]),
    MyLists = [ lists:sublist(Lines, X, (length(Lines) div (N))) || X <- lists:seq(1,length(Lines),(length(Lines) div (N))) ],
    %io:format("~p~n", [MyLists] ),
    %io:format("~p~n", [length(MyLists)]),
    %io:format("~p~n",[lists:nth(2,MyLists)]),
     for(1,length(MyLists), fun(Index) ->
				    filewrite(string:concat("./seg/F_", integer_to_list(Index)),lists:nth(Index,MyLists)),
	                           io:format("~p has been written to ~p ~n", [FileName,string:concat("./seg/F_", integer_to_list(Index)) ])
					end
	).

%%    for(1,length(MyLists), fun(Index) ->
%%	       {ok, O} = file:open(string:concat("./seg/F_", integer_to_list(Index)),write),
%%	       io:format(O, "~s~n",[lists:nth(Index, MyLists)]),
%%	       file:close(O),
%%	       io:format("~p has been written to ~p ~n", [FileName,string:concat("./seg/F_", integer_to_list(Index)) ])
%%		   end
%%	       ).
  



filewrite(File, L) ->
   case file:open(File, [write]) of
      {ok, Device} ->
         lists:foreach(fun(Line) -> writeline(Device, Line) end, L),
         file:close(Device)
   end.
writeline(Device, Line) -> writeline(Device, Line, os:type()).

writeline(Device, Line, {win32,_}) -> io:fwrite(Device, "~s\r\n", [Line]);
writeline(Device, Line, _) -> io:fwrite(Device, "~s\n", [Line]).
