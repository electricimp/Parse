#Parse

This library wraps Facebook’s [Parse Platform](https://parse.com).

The library comprises three classes: Parse, Parse.Object and Parse.Query. 

## Parse

## Constructor: Parse(*appId, restApiKey, [baseUrl], [version]*)

To instantiate a Parse object, you need to pass your Application ID and your REST API Key. Both of these can be located via your Parse app’s Dashboard: click on the cog icon and select ‘Keys’. 

Optionally, you can also pass the URL of the endpoint you’ll be communicating with and/or the Parse API version number. If you omit these optional values, the default to `https://api.parse.com` and `1`, respectively.

```squirrel
parse <- Parse(YOUR_APP_ID, YOUR_REST_API_KEY)
```

## Parse

## createObject(*className, [data]*)

To create a Parse object, call *createObject()* and pass your chosen class name and, optionally, some object data. 
You can later update this data &ndash; or add some &ndash; using the object’s [*set()*](#set) method. *createObject()* returns the new Parse object.

When you are ready to store the object in the Parse database in the cloud, call the object’s [*save()*](#save) method. This will automatically create the class if it has not yet been established. 

```squirrel
local sensor = parse.createObject("sensors", {"room":4, "type":"thermal"})
```

## getObject(*className, objectId, [callback]*)

To retrieve a Parse object from the database, call *getObject()*. Pass the name of the class you want, the Parse object ID (returned when you save the object) and, optionally, a callback function. If you provide a callback, the retrieval request will be processed asynchronously, otherwise it will be processed synchronously. The callback requires two parameters into which an error code and the retrieved object are placed, respectively. If you do not provide a callback, the method returns the object or `null` if an error was encountered.

```squirrel
sensorObjects <- []

// Code at some point creates Parse object and seves its objectId
// into the sensorObjects array

// Load sensor object

local sensor = parse.getObject("sensors", sensorObject[currentSensor])
if (object != null)
{
  // Sensor loaded, proceed to process
  
  . . . 
}
```

## destroyObject(*className, objectId, [callback]*)

To remove an object from the database, call *destroyObject()*. Pass the name of the class you want, the Parse object ID (returned when you save the object, see below) and, optionally, a callback function. If you provide a callback, the retrieval request will be processed asynchronously, otherwise it will be processed synchronously. The callback requires a single parameter into which a table will be passed comprising two keys: *err* and *data*. This table is returned by the method itself if you do not provide a callback.

```squirrel
sensorObjects <- []

// Code at some point creates Parse object and seves its objectId
// into the sensorObjects array

// Remove sensor object

local result = parse.getObject("sensors", sensorObject[currentSensor])
if (result.err != null)
{
  server.log ("Could not destroy object: " + err)
}
```

## createQuery(*className*)

To create an analytics query, which is used to retrieve all the objects within a specified class, call *createQuery()* and pass your chosen class name. You then add search terms to the query. To initiate the search, call the query’s [*find()*](#find) method.

```squirrel
local query = parse.createQuery("sensors")
```

## sendEvent(*eventName, [data], [callback]*)

To record an action &ndash; an ‘event’, in Parse terminology &ndash; call *sendEvent()*. Pass the name of the event and, optionally, JSON data associated with that event. You can also pass a callback function. If you provide a callback, the retrieval request will be processed asynchronously, otherwise it will be processed synchronously. The callback requires a single parameter into which a table will be passed comprising two keys: *err* and *data*. This table is returned by the method itself if you do not provide a callback.

## Parse.Object

## get(*key*)

Use the *get()* method to retrieve the value associated with the specified key from the target object.
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
sensorObjects <- []

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

sensor.set({"room":3})

// Update the record in the Parse database

local result = sensor.save()
if (result.err != null) server.log ("Could not update object: " + err)
```

## Parse.Query
<p id="find"></p>
## find(*[callback]*)

To initiate a query, instantiate a query object and call its *find()* method. This can take an optional callback function, in which case the query will be processed asynchronously, otherwise it will be processed synchronously. The callback requires a single parameter into which a table will be passed comprising two keys: *err* and *data*. This table is returned by the method itself if you do not provide a callback.

However you obtain the table, if this is the first time you saved the object, the results of the query will be placed in the *data* field. The results are associated with a key named *results* whose value is an array of zero or more tables, each of which contains the data from those objects that match the query.

```squirrel
sensorObjects <- []

// Code at some point creates Parse object and seves its objectId
// into the sensorObjects array

local query = parse.createQuery("sensors")
query.setConstraint("type", "$ne", "light")
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
