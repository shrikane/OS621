%% author: Yin Huang
%% Input: 1. segmentation files input path for example: './seg/'
%%        2. Destination 
%% Output: [ list[seg_number, values in the file]] written to destination 
-module(readseg).
-export([generatelist/2]).

generatelist(FilePath, Destination)->    
       file:delete(Destination),
	io:format("reading from ~p~n",[FilePath]),
    {ok, Filenames} = file:list_dir(FilePath),
    io:format("~p contains following files ~p~n", [FilePath, Filenames]),
      for(1,length(Filenames), fun(Index) ->
				       io:format("reading from ~p~n",[string:concat(FilePath,lists:nth(Index,Filenames))]),
		        {ok, Binary} = file:read_file(string:concat(FilePath,lists:nth(Index,Filenames))),
				  %     io:format("current index is ~p",[string:substr(lists:nth(Index,Filenames),3,1)]),
				  %     io:format(" ~p", [string:tokens(erlang:binary_to_list(Binary), "\n")])
		        Lines = lists:append([string:substr(lists:nth(Index,Filenames),3,1)],string:tokens(erlang:binary_to_list(Binary), "\n") ),
		       io:format("~p~n",[Lines]),
					   file:write_file(Destination,io_lib:fwrite("~p,",[Lines]),[append])
					   end
	  ).
    
    
for(Max, Max, F) ->
    [F(Max)];
for(I, Max,F) ->
    [F(I)|for(I+1,Max, F)].
