# Route of a message through the system

In case of a message sent from User A to User B, both of whom are served by
the same domain, the flow of the message through the system is as follows:

## 1. Receiving the stanza

User A's `ejabberd_receiver` receives the stanza and passes it to `ejabberd_c2s`.

## 2. Call to `user_send_packet`

Upon some minimal validation of the stanza a hook `user_send_packet` is called.

## 3. Privacy lists and `ejabberd_router:route/3`

The stanza is checked against any privacy lists in use and, in case of being allowed, routed by `ejabberd_router:route/3`.

## 4. Chain of routing

Further on, behaviour is configurable: `ejabberd_router:route/3` passes the stanza through
a chain of routing modules and applying `Mod:filter/3` and `Mod:route/3` from each of them.
Each of those modules has to implement `xmpp_router` behaviour.

A module can choose to either:

* drop the stanza, or route the stanza
* pass the stanza on unchanged, or modify the stanza and pass the result on

The set of routing modules can be set in configuration as `routing_modules`. The default
behaviour is the following:

* `mongoose_router_global`: runs a global `filter_packet` hook
* `mongoose_router_external_local`: checks if there is an external component registered for the
destination domain on the node we are on now, possibly routes the stanza to it
* `mongoose_router_external`: checks if there is an external component registered for the
destination domain on any node in the cluster, possibly routes the stanza to it
* `mongoose_router_localdomain`: checks if there is a local route registered for the destination
domain (i.e. there is an entry in mnesia `route` table), possibly routes the stanza to it
* `ejabberd_s2s`: tries to find or establish a connection to another server and send the stanza there

![You should see an image here; if you don't, use plantuml to generate it from routing.uml](routing.png)

## 5. Look up `external_component` and `route`

An external component or local route is obtained by looking up `external_component` and `route`
mnesia tables, respectively. Whats in there is either a fun to call or an MF to apply:

    ```erlang
    (ejabberd@localhost)2> ets:tab2list(route).
    [{route,<<"vjud.localhost">>,
            {apply_fun,#Fun<ejabberd_router.2.123745223>}},
     {route,<<"muc.localhost">>,
            {apply_fun,#Fun<mod_muc.2.63726579>}},
     {route,<<"localhost">>,{apply,ejabberd_local,route}}]
    ```

Here we see that for domain "localhost" the action to take
is to call `ejabberd_local:route()`.
Routing the stanza there means calling `mongoose_local_delivery:do_route/5`,
which calls `filter_local_packet` hook and, if passed, runs the fun or applies the handler.
In most cases, the handler is `ejabberd_local:route/3`.

## 6. `ejabberd_local` to `ejabberd_sm`

`ejabberd_local` routes the stanza to `ejabberd_sm` given it's
got at least a bare JID as the recipient.

## 7. `ejabberd_sm`

`ejabberd_sm` determines the available resources of User B,
takes into account their priorities and whether the message is
addressed to a particular resource or a bare JID and appropriately
replicates (or not) the message and sends it to the recipient's
`ejabberd_c2s` process(es).

In case no resources are available for delivery
(hence no `ejabberd_c2s` processes to pass the message to),
`offline_message_hook` is run.

## 8. `ejabberd_c2s`

`ejabberd_c2s` verifies the stanza against any relevant privacy lists
and sends it one the socket.
`user_receive_packet` hook is run to notify the rest of the system
about stanza delivery to User B.
