#Parse

This library wraps Facebook’s [Parse Platform](https://parse.com).

The library comprises three classes: Parse, Parse.Object and Parse.Query. 

## Parse
<p id="construct"></p>
## Constructor: Parse(*appId, restApiKey, [baseUrl], [version]*)

To instantiate a Parse object, you need to pass your Application ID and your REST API Key. Both of these can be located via your Parse app’s Dashboard: click on the cog icon and select ‘Keys’. 

Optionally, you can also pass the URL of the endpoint you’ll be communicating with and/or the Parse API version number. If you omit these optional values, the default to `https://api.parse.com` and `1`, respectively.

```squirrel
parse <- Parse(YOUR_APP_ID, YOUR_REST_API_KEY)
```

## Class Methods
<p id="create"></p>
## createObject(*className, [data]*)

To create a data object, call *createObject()* and pass your chosen class name and, optionally, some data. 
You can later update this data &ndash; or add some &ndash; using the object’s [*set()*](#set) method. *createObject()* returns the new Parse object.

When you are ready to store the object in the Parse database in the cloud, call the object’s [*save()*](#save) method. This will automatically create the class if it has not yet been established. 

```squirrel
local sensor = parse.createObject("sensors", {"room":4, "type":"thermal"})
```

## getObject(*className, objectId, [callback]*)

To retrieve a data object from the database, call *getObject()*. Pass the name of the class you want, the Parse object ID (returned when you first saved the object) and, optionally, a callback function. If you provide a callback, the retrieval request will be processed asynchronously, otherwise it will be processed synchronously. The callback requires two parameters into which an error code and the retrieved object are placed, respectively. If you do not provide a callback, the method returns the object or `null` if an error was encountered.

```squirrel
sensorObjectIds <- []

// Code at some point creates Parse object and seves its objectId
// into the sensorObjectIds array

// Load current sensor object synchronously

local sensor = parse.getObject("sensors", sensorObjectIds[currentSensor])
if (object != null)
{
  // Sensor loaded, proceed to process it
  
  . . . 
}

// Load current sensor object asynchronously

parse.getObject("sensors", sensorObjectIds[currentSensor], function(err, object) {
  if (object != null)
  {
    // Sensor loaded, proceed to process it
    . . . 
  }
  else
  {
    server.log("Error " + err.code + ": " + err.error)
  }
})
```

## destroyObject(*className, objectId, [callback]*)

To remove a data object from the database, call *destroyObject()*. Pass the name of the class you want, the Parse object ID (returned when you save the object, see below) and, optionally, a callback function. If you provide a callback, the retrieval request will be processed asynchronously, otherwise it will be processed synchronously. The callback requires a single parameter into which a table will be passed comprising two keys: *err* and *data*. This table is returned by the method itself if you do not provide a callback.

```squirrel
sensorObjectIds <- []

// Code at some point creates Parse object and seves its objectId
// into the sensorObjectIds array

// Remove current sensor object synchronously

local result = parse.destroyObject("sensors", sensorObjectIds[currentSensor])
if (result.err != null)
{
  server.log ("Could not destroy object: " + err.error)
}

// Remove current sensor object asynchronously

parse.destroyObject("sensors", sensorObjectIds[currentSensor], function(err, data) {
  if (err != null)
  {
    server.log ("Could not destroy object: " + err.error) 
  }
})
```

## createQuery(*className*)

To create an analytics query, which is used to retrieve all the objects within a specified class, call *createQuery()* and pass your chosen class name. You then add search terms to the query. To initiate the search, call the query’s [*find()*](#find) method.

```squirrel
local query = parse.createQuery("sensors")
```

## sendEvent(*eventName, [data], [callback]*)

To record an action &ndash; an ‘event’, in Parse terminology &ndash; call *sendEvent()*. Pass the name of the event and, optionally, JSON data associated with that event. You can also pass a callback function. If you provide a callback, the retrieval request will be processed asynchronously, otherwise it will be processed synchronously. The callback requires a single parameter into which a table will be passed comprising two keys: *err* and *data*. This table is returned by the method itself if you do not provide a callback.

## Parse.Object

## Constructor: Parse.Object(*parse, className, [data]*)

This method takes a Parse object ([see above](#construct)), the desired class name and, optionally, data with which to initialize the new object. It returns the new data object. It is typically not used directly but via the Parse object’s [*createObject()*](#create) method.

## Class Methods

## get(*key*)

Use the *get()* method to retrieve the value associated with the specified key from the target object.

```squirrel
local rooms = ["Bedroom", "Bathroom", "Hall", "Living Room", "Kitchen", "Garden"]
foreach (index, sensor in sensorList)
{
  server.log("Sensor " + format("%u", index + 1) + " is located in the " + rooms[sensor.get("room")])
}

// Displays
// Sensor 1 is located in the Hall
// Sensor 2 is located in the Kitchen
// Sensor 3 is located in the Kitchen
```

<p id="set"></p>
## set(*key*, *data*)

The *set()* method allows you to add data values to a Parse object. You provide the name of the key with which the data will be associated, and the data itself.

```squirrel
local sensor = parse.createObject("sensors", {"room":4, "type":"thermal"})

. . .

// Update the sensor definition with its manufacturer data

sensor.set("make", "BMP")

// Relocate it to room 3

sensor.set("room", 3)

```

## unset(*key*)

You can remove a key and any data with which it is associated by calling *unset()* on the target object. Pass the key you wish to remove.
<p id="save"></p>
## save(*[callback]*)

When your object is ready to save in the Parse database, call its *save()* method. You can choose to provide a callback function. If you do, saving operation will be processed asynchronously, otherwise it will be processed synchronously. The callback requires a single parameter into which a table will be passed comprising two keys: *err* and *data*. This table is returned by the method itself if you do not provide a callback.

However you obtain the table, if this is the first time you saved the object, you should query *data* for the key *objectId*. This is used by the *getObject()* and *destroyObject()* methods to identify specific objects saved within the Parse database. It is also used internally by an existing object to identify itself when, having perhaps changed the data it contains, you call *save()* again. If the object already exists in the Parse database, its *objectId* is used to ensure its record is updated rather than uses as the basis of a new record.

```squirrel
local sensor = parse.createObject("sensors", {"room":4, "type":"thermal"})

// Synchronous save

local result = sensor.save()
if (result.err != null)
{
  server.log ("Could not save object: " + err)
}
else
{
  if ("objectId" in result.data)
  {
    sensorObjects.append(result.data.objectId)
  }
}

. . . 

// Relocate the sensor to room 2

sensor.set({"room":2})

// Update the record in the Parse database asynchronously this time

sensor.save(function(err, data) {
  if (err != null) server.log ("Could not update object: " + err.error)
})
```

## Parse.Query

## Class Methods

The following 11 methods are used on a Parse Query object to define its search parameters. Once the query has been designed, it is initiated using the query’s [*find()*](#find) method.

## lessThan(*key, value*)

Sets the query to find all data objects in the Parse database class with the key *key* and whose own value associated with that key is less than *value*.

## lessThanOrEqualTo(*key, value*)

Sets the query to find all data objects in the Parse database class with the key *key* and whose own value associated with that key is less than or equal to *value*.

## greaterThan(*key, value*)

Sets the query to find all data objects in the Parse database class with the key *key* and whose own value associated with that key is greater than *value*.

## greaterThanOrEqualTo(*key, value*)

Sets the query to find all data objects in the Parse database class with the key *key* and whose own value associated with that key is greater than or equal to *value*.

## notEqualTo(*key, value*)

Sets the query to find all data objects in the Parse database class with the key *key* and whose own value associated with that key does not equal *value*.

## containedIn(*key, array*)

Sets the query to find all data objects in the Parse database class with the key *key* and whose value matches one of the elements in the passed array.

```squirrel
local query = parse.createQuery("sensors")
query.containedIn("type", ["light", "motion", "thermal", "pressure"])
```

##notContainedIn(*key, array*)

Sets the query to find all data objects in the Parse database class with the key *key* and whose value does not match one of the elements in the passed array.

```squirrel
local query = parse.createQuery("sensors")
query.notContainedIn("type", ["light", "motion", "thermal", "pressure"])
```

##exists(*key*)

Sets the query to find all data objects in the Parse database class whose *key* contains a value (as opposed to `null`). 

##notExists(*key*)

Sets the query to find all data objects in the Parse database class whose *key* contains `null`.

##select(*keyArray*)

Sets the query to find all data objects in the Parse database class which have non-`null` values for all the keys listed in *keyArray*. 

```squirrel
local query = parse.createQuery("sensors")

// Find all sensors with a recorded location

query.select(["room", "floor", "building"])
```

##setConstraint(*key, parseConstraint, value*)

This method provides a means to enter Parse query search parameters (‘constraints’) without recourse to the convenience methods listed above. The values of *parseConstraint*, all strings, may be any one of the following:

<table width="100%">
  <tbody><tr><th align="left"><i>parseConstraint</i></th><th align="left">Operation</th></tr>
  <tr><td>$lt</td><td>Less than</td></tr>
  <tr><td>$lte</td><td>Less than or equal to</td></tr>
  <tr><td>$gt</td><td>Greater than</td></tr>
  <tr><td>$gte</td><td>Greater than or equal to</td></tr>
  <tr><td>$ne</td><td>Not equal to</td></tr>
  <tr><td>$in</td><td>Contained in</td></tr>
  <tr><td>$nin</td><td>Not Contained in</td></tr>
  <tr><td>$exists</td><td>A value is set for the key</td></tr>
  <tr><td>$select</td><td>Matches a value for a key in the supplied array of keys</td></tr>
  <tr><td>$dontSelect</td><td>Requires that a key’s value not match a key in the supplied array of keys</td></tr>
  <tr><td>$all</td><td>Contains all of the given values</td></tr>
  </tbody>
</table>

<p id="find"></p>
## find(*[callback]*)

To initiate a query, instantiate a query object and call its *find()* method. This can take an optional callback function, in which case the query will be processed asynchronously, otherwise it will be processed synchronously. The callback requires a single parameter into which a table will be passed comprising two keys: *err* and *data*. This table is returned by the method itself if you do not provide a callback.

However you obtain the table, if this is the first time you saved the object, the results of the query will be placed in the *data* field. The results are associated with a key named *results* whose value is an array of zero or more tables, each of which contains the data from those objects that match the query.

```squirrel
local query = parse.createQuery("sensors").notEqual("type", "light")
local search = query.find()

if (search.err != null)
{
  server.log ("Could not perform query: " + err)
}
else
{
  server.log("The following rooms contain motion or thermal sensors:")
  
  foreach (sensor in search.data.results)
  {
    server.log("Room " + sensor.room)
  }
}
```

## License

The Parse library is licensed under the [MIT License](./LICENSE).
