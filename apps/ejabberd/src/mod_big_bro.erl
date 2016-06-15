%%%-------------------------------------------------------------------
%%% @author konstantin.shamko
%%% @copyright (C) 2016, Oxagile LLC
%%% @doc
%%%
%%% @end
%%% Created : 15. Jun 2016 10:20 AM
%%%-------------------------------------------------------------------
-module(mod_big_bro).
-author("konstantin.shamko").

-behaviour(gen_mod).
-include("../include/ejabberd.hrl").

%% API
-export([start/2, stop/1]).

-export([process_user_packet/3]).

start(Host, _Opts) ->
  ?WARNING_MSG("Hello, ejabberd world!", []),
  ejabberd_hooks:add(user_send_packet, Host, ?MODULE, process_user_packet, 100),
  ok.

stop(Host) ->
  ?WARNING_MSG("Bye bye, ejabberd world!", []),
  ejabberd_hooks:delete(user_send_packet, Host, ?MODULE, user_send_packet, 100),
  ok.


process_user_packet(From, To, Packet) ->
  ?WARNING_MSG("Send packet~n    from ~p ~n    to ~p~n    packet ~p.",  [From, To, Packet]),
  ok.

