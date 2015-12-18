var DataSource, ExprCleaner, ExprCompiler, ExprComponent, FilterExprComponent, H, MWaterDataSource, OmniBoxExprComponent, R, React, ReactDOM, Schema, value,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

React = require('react');

ReactDOM = require('react-dom');

R = React.createElement;

H = React.DOM;

Schema = require("mwater-expressions").Schema;

ExprComponent = require('./ExprComponent');

ExprCleaner = require("mwater-expressions").ExprCleaner;

OmniBoxExprComponent = require('./OmniBoxExprComponent');

ExprCompiler = require("mwater-expressions").ExprCompiler;

DataSource = require('mwater-expressions').DataSource;

FilterExprComponent = require('./FilterExprComponent');

$(function() {
  var TestComponent, dataSource, schema;
  schema = new Schema();
  schema = schema.addTable({
    id: "t1",
    name: {
      en: "T1"
    },
    primaryKey: "primary",
    contents: [
      {
        id: "text",
        name: {
          en: "Text"
        },
        type: "text"
      }, {
        id: "number",
        name: {
          en: "Number"
        },
        type: "number"
      }, {
        id: "enum",
        name: {
          en: "Enum"
        },
        type: "enum",
        enumValues: [
          {
            id: "a",
            name: "A"
          }, {
            id: "b",
            name: "B"
          }
        ]
      }, {
        id: "enumset",
        name: {
          en: "EnumSet"
        },
        type: "enumset",
        enumValues: [
          {
            id: "a",
            name: "A"
          }, {
            id: "b",
            name: "B"
          }
        ]
      }, {
        id: "date",
        name: {
          en: "Date"
        },
        type: "date"
      }, {
        id: "datetime",
        name: {
          en: "Datetime"
        },
        type: "datetime"
      }, {
        id: "boolean",
        name: {
          en: "Boolean"
        },
        type: "boolean"
      }, {
        id: "1-2",
        name: {
          en: "T1->T2"
        },
        type: "join",
        join: {
          fromTable: "t1",
          fromColumn: "primary",
          toTable: "t2",
          toColumn: "t1",
          op: "=",
          multiple: true
        }
      }
    ]
  });
  schema = schema.addTable({
    id: "t2",
    name: {
      en: "T2"
    },
    primaryKey: "primary",
    ordering: "number",
    contents: [
      {
        id: "t1",
        name: {
          en: "T1"
        },
        type: "uuid"
      }, {
        id: "text",
        name: {
          en: "Text"
        },
        type: "text"
      }, {
        id: "number",
        name: {
          en: "Number"
        },
        type: "number"
      }, {
        id: "2-1",
        name: {
          en: "T2->T1"
        },
        type: "join",
        join: {
          fromTable: "t2",
          fromColumn: "t1",
          toTable: "t1",
          toColumn: "primary",
          op: "=",
          multiple: false
        }
      }
    ]
  });
  dataSource = {
    performQuery: (function(_this) {
      return function(query, cb) {
        return cb(null, [
          {
            value: "abc"
          }, {
            value: "xyz"
          }
        ]);
      };
    })(this)
  };
  TestComponent = (function(superClass) {
    extend(TestComponent, superClass);

    function TestComponent() {
      this.handleValueChange = bind(this.handleValueChange, this);
      TestComponent.__super__.constructor.apply(this, arguments);
      this.state = {
        value: value
      };
    }

    TestComponent.prototype.handleValueChange = function(value) {
      value = new ExprCleaner(schema).cleanExpr(value);
      return this.setState({
        value: value
      });
    };

    TestComponent.prototype.render = function() {
      dataSource;
      return H.div({
        style: {
          padding: 10
        }
      }, R(FilterExprComponent, {
        schema: schema,
        dataSource: dataSource,
        table: "t1",
        value: this.state.value,
        onChange: this.handleValueChange
      }), H.br(), H.br(), H.pre(null, JSON.stringify(this.state.value, null, 2)));
    };

    return TestComponent;

  })(React.Component);
  return ReactDOM.render(R(TestComponent), document.getElementById("main"));
});

value = {
  "type": "op",
  "table": "t1",
  "op": "contains",
  "exprs": [
    {
      "type": "field",
      "table": "t1",
      "column": "enumset"
    }, null
  ]
};

MWaterDataSource = (function(superClass) {
  extend(MWaterDataSource, superClass);

  function MWaterDataSource(apiUrl, client, caching) {
    if (caching == null) {
      caching = true;
    }
    this.apiUrl = apiUrl;
    this.client = client;
    this.caching = caching;
  }

  MWaterDataSource.prototype.performQuery = function(query, cb) {
    var headers, url;
    url = this.apiUrl + "jsonql?jsonql=" + encodeURIComponent(JSON.stringify(query));
    if (this.client) {
      url += "&client=" + this.client;
    }
    headers = {};
    if (!this.caching) {
      headers['Cache-Control'] = "no-cache";
    }
    return $.ajax({
      dataType: "json",
      url: url,
      headers: headers
    }).done((function(_this) {
      return function(rows) {
        return cb(null, rows);
      };
    })(this)).fail((function(_this) {
      return function(xhr) {
        return cb(new Error(xhr.responseText));
      };
    })(this));
  };

  return MWaterDataSource;

})(DataSource);
