%%%-------------------------------------------------------------------
%%% @author Simone Stefani
%%% @copyright (C) 2017, simonestefani.me
%%% Created : 23. Jan 2017 17:51
%%%-------------------------------------------------------------------
-module(eager).

-export([eval_expr/2, eval_match/3, eval_seq/2, eval/1, run/0]).


%%%-------------------------------------------------------------------
%%% Testing functions
%%%-------------------------------------------------------------------
run() ->
  Seq = [{match, {var, x}, {atm, a}},
    {match, {var, y}, {cons, {var, x}, {atm, b}}},
    {match, {cons, ignore, {var, z}}, {var, y}},
    {var, z}],
  eval(Seq).

eval(Seq) ->
  eval_seq(Seq, []).


%%%-------------------------------------------------------------------
%%% Internal functions
%%%-------------------------------------------------------------------

% Evaluate simple expressions of terms: 
% atoms, variables and cons cells
eval_expr({atm, Id}, _) ->
  {ok, Id};
eval_expr({var, Id}, Env) ->
  case env:lookup(Id, Env) of
    false ->
      error;
    {Id, Str} ->
      {ok, Str}
  end;
eval_expr({cons, Head, Tail}, Env) ->
  case eval_expr(Head, Env) of
    error ->
      error;
    {ok, StrHead} ->
      case eval_expr(Tail, Env) of
        error ->
          error;
        {ok, StrTail} ->
          {ok, [StrHead | StrTail]}
      end
  end.


eval_match(ignore, _, Env) ->
  {ok, Env};
eval_match({atm, _Id}, _Str, Env) ->
  {ok, Env};
eval_match({var, Id}, Str, Env) -> % Check if variable with given Id is in Env...
  case env:lookup(Id, Env) of
    false ->
      {ok, env:add(Id, Str, Env)}; % if not add it
    {Id, Str} ->
      {ok, Env}; % if yes return it
    {Id, _} ->
      fail % the Id is in the Env but bound to a different Str
  end;
eval_match({cons, HeadPa, TailPa}, [Head | Tail], Env) -> % Check for a double pattern match
  case eval_match(HeadPa, Head, Env) of
    fail ->
      fail;
    {ok, NewEnv} ->
      eval_match(TailPa, Tail, NewEnv)
  end;
eval_match(_, _, _) -> % Catch other possible results and fail
  fail.


eval_seq([Exp], Env) ->
  eval_expr(Exp, Env);
eval_seq([{match, Ptr, Exp} | Seq], Env) ->
  case eval_expr(Exp, Env) of
    error ->
      error;
    {ok, Str} ->
      case eval_match(Ptr, Str, Env) of
        fail ->
          error;
        {ok, NewEnv} ->
          eval_seq(Seq, NewEnv)
      end
  end.