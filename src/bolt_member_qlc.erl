-module(bolt_member_qlc).
-export([ids_above/2, ids_within/3, role_members/2, total_role_members/2]).
-export([recent_joins_q/2]).

-define(CACHE, 'Elixir.Nostrum.Cache.MemberCache').
-define(USER_CACHE, 'Elixir.Nostrum.Cache.UserCache').
-include_lib("stdlib/include/qlc.hrl").

%% @doc Return member IDs on the given guild above the given `LowerEnd'.
ids_above(RequestedGuildId, LowerEnd) ->
    Q = qlc:q([{MemberId, Member} || {{GuildId, MemberId}, Member} <- ?CACHE:query_handle(),
                                      GuildId =:= RequestedGuildId,
                                      MemberId >= LowerEnd]),
    eval(Q).

%% @doc Return member IDs on the given guild within the range between
%% `LowerEnd' and `UpperEnd'.
ids_within(RequestedGuildId, LowerEnd, UpperEnd) ->
    Q = qlc:q([{MemberId, Member} || {{GuildId, MemberId}, Member} <- ?CACHE:query_handle(),
                                     GuildId =:= RequestedGuildId,
                                     MemberId >= LowerEnd,
                                     MemberId =< UpperEnd]),
    eval(Q).

%% @doc Return members in the form {MemberId, JoinedAt, Member}.
recent_joins_q(RequestedGuildId, ShouldHaveRoles) ->
    RoleLengthMin = case ShouldHaveRoles of
        true -> 1;
        false -> 0
    end,
    qlc:q([Member
               || {{GuildId, _MemberId}, Member} <- ?CACHE:query_handle(),
                  GuildId =:= RequestedGuildId,
                  length(map_get(roles, Member)) >= RoleLengthMin]).


%% @doc Return members of the given role on the given guild.
role_members(GuildId, RoleId) ->
    Q = qlc:q([{Member, User}
               || {{ThisGuildId, MemberId}, Member} <- ?CACHE:query_handle(),
                  ThisGuildId =:= GuildId,
                  lists:member(RoleId, map_get(roles, Member)),
                  {UserId, User} <- ?USER_CACHE:query_handle(),
                  UserId =:= MemberId
              ]),
    eval(Q).

%% @doc Return total members of the given role on the given guild.
total_role_members(GuildId, RoleId) ->
    Q = qlc:q([1
               || {{ThisGuildId, _MemberId}, Member} <- ?CACHE:query_handle(),
                  ThisGuildId =:= GuildId,
                  lists:member(RoleId, map_get(roles, Member))
              ]),
    ?CACHE:wrap_qlc(fun () ->
        qlc:fold(fun (_, Acc) -> Acc + 1 end, 0, Q)
    end).

%% @doc Evaluate the given query handle in the `wrap_qlc' context.
%% @private
eval(Q) ->
    ?CACHE:wrap_qlc(fun () -> qlc:e(Q) end).
