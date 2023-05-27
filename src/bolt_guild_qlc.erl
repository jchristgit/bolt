-module(bolt_guild_qlc).
-export([count/0, total_member_count/0]).

-define(CACHE, 'Elixir.Nostrum.Cache.GuildCache').
-include_lib("stdlib/include/qlc.hrl").

count() ->
    Q = qlc:q([1 || _ <- ?CACHE:query_handle()]),
    ?CACHE:wrap_qlc(fun () ->
        qlc:fold(fun (_, Acc) -> Acc + 1 end, 0, Q)
    end).

total_member_count() ->
    Q = qlc:q([Members || {_, #{member_count := Members}} <- ?CACHE:query_handle()]),
    ?CACHE:wrap_qlc(fun () ->
        qlc:fold(fun (Count, Acc) -> Acc + Count end, 0, Q)
    end).
