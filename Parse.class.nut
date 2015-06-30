class Parse {
    static version = [1,0,1];

    _appId = null;
    _apiKey = null;

    _baseUrl = null;
    _version = null;

    // ERRORS
    static ERR_NULL_DATA = "ERR_NULL_DATA: data cannot be null";
    static ERR_NO_OBJECT_ID = "ERR_NO_OBJECTID: missing require parameter 'objectId'";

    constructor(appId, apiKey, baseUrl = null, version = null) {
        _appId = appId;
        _apiKey = apiKey;

        if (baseUrl != null) _baseUrl = baseUrl;
        else _baseUrl = "https://api.parse.com"

        if (version != null) _version = version.tostring();
        else _version = "1";
    }

    /******************** Objects ********************/
    function createObject(className, data = null) {
        return Parse.Object(this, className, data);
    }

    function getObject(className, id, cb = null) {
        local obj = Parse.Object(this, className, { objectId = id });
        if (cb == null) {
            obj.fetch();
            return obj;
        }

        obj.fetch(function(err, data) {
            cb(err, obj);
        });
    }

    function destroyObject(className, id, cb = null) {
        local obj = Parse.Object(this, className, { objectId = id });
        return obj.destroy(cb);
    }

    function createQuery(className) {
        return Parse.Query(this, className);
    }

    /******************** Analytics ********************/
    function sendEvent(eventName, data = null, cb = null) {
        if (data == null) data = {};

        local resource = format("/events/%s", eventName);
        return _processReq(request("POST", resource, null, data), cb);
    }

    /******************** Cloud Functions ********************/
    function runCloudFunction(fct, data = null, cb = null) {
        if (data == null) data = {};

        local resource = format("/functions/%s", fct);
        return _processReq(request("POST", resource, null, data), cb);
    }

    /******************** Utility Methods ********************/
    function request(verb, path, additionalHeaders, data) {
        local url = format("%s/%s%s", _baseUrl, _version, path);

        local headers = _baseHeaders();
        if (additionalHeaders != null) {
            foreach(idx,val in additionalHeaders) {
                if (idx in headers) headers[idx] = val;
                else headers[idx] <- val;
            }
        }

        local encodedData = http.jsonencode(data);
        return http.request(verb, url, headers, encodedData);
    }

    /******************** PRIVATE METHODS (DO NOT CALL) ********************/
    function _processReq(req, cb) {
        if (cb == null) return _processResp(req.sendsync());

        return req.sendasync(function(resp) {
            local respData = _processResp(resp);
            cb(respData.err, respData.data);
        }.bindenv(this));
    }

    function _processResp(resp) {
        local data = null;
        local err = null;

        try {
            if (resp.statuscode >= 200 && resp.statuscode < 300) {
                if (resp.body == null || resp.body == "") {
                    data = {};
                } else {
                    data = http.jsondecode(resp.body);
                }
            } else {
                if (resp.body == null || resp.body == "") {
                    err = resp.statuscode;
                } else {
                    err = http.jsondecode(resp.body);
                }

                err = { "code": resp.statuscode, "error": err };
            }
        } catch (ex) {
            err = { "code": -1, "error": ex };
        }

        return { "err": err, "data": data };
    }

    function _baseHeaders() {
        return {
            "X-Parse-Application-Id": _appId,
            "X-Parse-REST-API-Key": _apiKey,
            "Content-Type": "application/json"
        };
    }

    function _typeof() {
        return "Parse";
    }
}

class Parse.Object {
    _parse = null;
    _className = null;
    _data = null;

    constructor(parse, className, data = null) {
        _parse = parse;
        _className = className;
        _data = data;
    }

    function get(attr) {
        if (attr in _data) return _data[attr];
        else return null;
    }

    function set(attr, data) {
        if (!(attr in _data)) _data[attr] <- null;
        _data[attr] = data;
    }

    function unset(attr) {
        if (attr in _data) delete _data[attr];
    }

    function save(cb = null) {
        // validate request
        if (_data == null) throw _parse.ERR_NULL_DATA;

        // setup verb & resource
        local verb = "POST";
        local resource = format("/classes/%s", _className);
        if ("objectId" in _data) {
            verb = "PUT"
            resource = format("/classes/%s/%s", _className, _data.objectId);
        }

        // create & process request
        return _processObjectRequest(_parse.request(verb, resource, null, _data), cb);
    }

    function fetch(cb = null) {
        // validate request
        if (!("objectId" in _data)) throw _parse.ERR_NO_OBJECT_ID;

        // setup url
        local resource = format("/classes/%s/%s", _className, _data.objectId);

        // create & process request
        return _processObjectRequest(_parse.request("GET", resource, null, null), cb);
    }

    function destroy(cb = null) {
        // validate request
        if (!("objectId" in _data)) throw _parse.ERR_NO_OBJECT_ID;

        // setup url
        local resource = format("/classes/%s/%s", _className, _data.objectId);

        // create & process request
        local req = _parse.request("DELETE", resource, null, null);

        if (cb == null) return _processDestroyResponse(req.sendsync());

        return req.sendasync(function(resp) {
            local respData = _processDestroyResponse(resp);
            cb(respData.err, respData.data);
        }.bindenv(this));
    }

    /*************** PRIVATE METHODS (DO NOT CALL) ***************/
    function _typeof() {
        return "Parse.Object";
    }

    function _processObjectRequest(req, cb = null){
        // process request
        if (cb == null) return _processObjectResponse(req.sendsync());

        return req.sendasync(function(resp) {
            local respData = _processObjectResponse(resp);
            cb(respData.err, respData.data);
        }.bindenv(this));
    }

    function _processObjectResponse(resp) {
        local data = null;
        local err = null;

        try {
            local respData = http.jsondecode(resp.body);
            if (resp.statuscode >= 200 && resp.statuscode < 300) {
                foreach(idx, val in respData) {
                    if (!(idx in _data)) _data[idx] <- null;
                    _data[idx] = val;
                }

                data = _data;
            } else {
                err = respData;
            }
        } catch (ex) {
            err = { code = -1, error = ex };
        }

        return { err = err, data = data };
    }

    function _processDestroyResponse(resp) {
        local data = false;
        local err = null;

        try {
            local respData = http.jsondecode(resp.body);
            if (resp.statuscode >= 200 && resp.statuscode < 300) {
                _data = null
                data = true;
            } else {
                err = respData;
            }
        } catch (ex) {
            err = { code = -1, error = ex };
        }

        return { err = err, data = data };
    }

}

class Parse.Query {
    _parse = null;
    _className = null;

    _selects = null;
    _constraints = null;

    _orderBy = null;
    _limit = null;
    _skip = null;

    constructor(parse, className) {
        _parse = parse;
        _className = className;

        _selects = [];
        _constraints = {};
    }

    /******************** Setup Functions ********************/
    function limit(numResults) {
        _limit = numResults;

        return this;
    }

    function skip(numResults) {
        _skip = numResults

        return this;
    }

    function orderBy(attr) {
        if (_orderBy != null) _orderBy += ",";
        else _orderBy = "";
        _orderBy += attr;

        return this;
    }

    function lessThan(attr, val) {
        return setConstraint(attr, "$lt", val);
    }

    function lessThanOrEqualTo(attr, val) {
        return setConstraint(attr, "$lte", val);
    }

    function greaterThan(attr, val) {
        return (attr, "$gt", val);
    }

    function greaterThanOrEqualTo(attr, val) {
        return setConstraint(attr, "$gte", val);
    }

    function notEqualTo(attr, val) {
        return setConstraint(attr, "$ne", val);
    }

    function containedIn(attr, arr) {
        return setConstraint(attr, "$in", arr);
    }

    function notContainedIn(attr, arr) {
        return setConstraint(attr, "$nin", arr);
    }

    function exists(attr) {
        return setConstraint(attr, "$exists", true);
    }

    function notExists(attr) {
        return setConstraint(attr, "$exists", false);
    }

    function select(keys) {
        if (typeof(keys) == "string") _selects.push(keys);
        else {
            foreach(key in keys) {
                _selects.push(key);
            }
        }

        return this;
    }

    function setConstraint(attr, constraint, val) {
        if (!(attr in _constraints)) _constraints[attr] <- {};
        if (!(constraint in _constraints[attr])) _constraints[attr][constraint] <- null;
        _constraints[attr][constraint] = val;

        return this;
    }

    /******************** Exec Functions ********************/
    function find(cb = null) {
        // setup url
        local resource = format("/classes/%s", _className);

        // create & process request
        local queryData = _buildQueryData();
        local data = http.urlencode(queryData);

        return _parse._processReq(_parse.request("GET", resource + "?" + data, null, {}), cb);
    }

    /******************** PRIVATE METHODS (DO NOT CALL ********************/
    function _buildQueryData() {
        local data = {};
        if (_orderBy != null) data["order"] <- _orderBy;
        if (_limit != null) data["limit"] <- _limit;
        if (_skip != null) data["skip"] <- _skip;
        if (_selects != null && _selects.len() > 0) data["keys"] <- null;

        foreach(field in _selects) {
            if (data.keys != null) data.keys += ",";
            data.keys += field;
        }

        if (_constraints != null) data["where"] <- null;
        data.where = http.jsonencode(_constraints);
        return data;
    }
}
