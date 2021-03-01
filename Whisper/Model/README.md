#  Application Data Model

## Design Pattern

This application conforms to pub/sub model where:

     1. `source`s  are created, then 
     
     2.  `await` for connection to database, and then
     
     3  `notify` downstream `pipe`s who are `await`ing the data
     
     4. intermediate `pipes`s will `await` from `source`  and `filter`  or `boolean` function over list of data as needed
     
     6. The view is the final `consumer` and render data when it appears
     
     7. Data "gets here when it gets here". So  you will not see code of form:
     
     let data = source.getAllData()
     let res = doSomething(with: data)
     renderView(from: res)
     `
 
 because `data` is most likely empty by the time line 2 is executed. Because `source` is still `await`ing data from the server


## Present Architecture

key:  >>=  is `await` information, ie:    `source >= pipe >>= consumer`

Data in this application flows in this exact manner: 

    1. myProfile:    firebase >>=  UserAuth >>= view
    
    2. BFS search:   firebase >>=  UserAuth >>= GroupList >>= [User] >>= [Group] >>= UserList >>= view
    
    3. groups:       firebase >>= GroupList >>= [Group] >>= [view]
    
    3. chats:        firebase >>=  UserAuth >>= (GroupList,UserList) >>= ChatQueue >>= [view]
    
    4. newsfeed:     firebase >>=  UserAuth >>= (GroupList, UserList, [Chat]) >>= ActivityQueue >>= [view]

`UserAuth` is a single special instance of `User` for current user only, w/ privilidged `read/write` access to its own data
Each `pipe` will also `IO`   with the `firebase` server as needed. Except the `view`. `view`s only `consume` information.

The least obvious ilne in the pseudo-code above is line 2, this bit:

    `GroupList >>= [User] >>= [Group] >>= UserList`
    
 is doing a `BFS` over friend group two hops out.  That is, as `groupList`  is loading groups where I belong, every `user`  within each
 group is loaded, their `group`s are then loaded, and `UserList` will subscribe to this set of groups, and get all its users. Thus
 we have `friendOf (friendOf ( me ) )`, or a BFS.
 

This computation runs for the duration of the app to:
 1. load user's profile image and cache it. These users will appear somewhere in chat with high prob. so eager loading is prudent
 2. fill a table of "people you may know"
 3. As more users join my groups, their groups and users w/i those groups will come down the pipeline as well

A single run of   `search`  is a one-off creation of the pipe, where if I search for `foo`, then an instance of `firebase` is created parameterized
by `foo`. That is:

    firebase `matching` "foo" >>= GroupList >>= [Group] >>= view

will get me a list of `Group`s matching on `foo`. This pipe *will not* persist over the course of the application.


## API

1.  Use API/PlayList for all create/update/remove opertions
2. Use [Model].{function_name} for all read operatons
