var ExprCleaner, ExprElementBuilder, FilterExprComponent, H, R, React, RemovableComponent, StackedComponent, _, update,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

_ = require('lodash');

React = require('react');

R = React.createElement;

H = React.DOM;

update = require('update-object');

ExprCleaner = require("mwater-expressions").ExprCleaner;

ExprElementBuilder = require('./ExprElementBuilder');

StackedComponent = require('./StackedComponent');

RemovableComponent = require('./RemovableComponent');

module.exports = FilterExprComponent = (function(superClass) {
  extend(FilterExprComponent, superClass);

  FilterExprComponent.propTypes = {
    schema: React.PropTypes.object.isRequired,
    dataSource: React.PropTypes.object.isRequired,
    table: React.PropTypes.string.isRequired,
    value: React.PropTypes.object,
    onChange: React.PropTypes.func
  };

  FilterExprComponent.contextTypes = {
    locale: React.PropTypes.string
  };

  function FilterExprComponent() {
    this.handleRemove = bind(this.handleRemove, this);
    this.handleAndRemove = bind(this.handleAndRemove, this);
    this.handleAndChange = bind(this.handleAndChange, this);
    this.handleChange = bind(this.handleChange, this);
    this.handleAddFilter = bind(this.handleAddFilter, this);
    FilterExprComponent.__super__.constructor.apply(this, arguments);
    this.state = {
      displayNull: false
    };
  }

  FilterExprComponent.prototype.handleAddFilter = function() {
    if (this.props.value && this.props.value.op === "and") {
      this.props.onChange(update(this.props.value, {
        exprs: {
          $push: [null]
        }
      }));
      return;
    }
    if (this.props.value) {
      this.props.onChange({
        type: "op",
        op: "and",
        table: this.props.table,
        exprs: [this.props.value, null]
      });
      return;
    }
    return this.setState({
      displayNull: true
    });
  };

  FilterExprComponent.prototype.handleChange = function(expr) {
    expr = new ExprCleaner(this.props.schema).cleanExpr(expr, {
      table: this.props.table,
      type: "boolean"
    });
    return this.props.onChange(expr);
  };

  FilterExprComponent.prototype.handleAndChange = function(i, expr) {
    return this.handleChange(update(this.props.value, {
      exprs: {
        $splice: [[i, 1, expr]]
      }
    }));
  };

  FilterExprComponent.prototype.handleAndRemove = function(i) {
    return this.handleChange(update(this.props.value, {
      exprs: {
        $splice: [[i, 1]]
      }
    }));
  };

  FilterExprComponent.prototype.handleRemove = function() {
    this.setState({
      displayNull: false
    });
    return this.handleChange(null);
  };

  FilterExprComponent.prototype.renderAddFilter = function() {
    return H.div(null, H.a({
      onClick: this.handleAddFilter
    }, "+ Add Filter"));
  };

  FilterExprComponent.prototype.render = function() {
    if (this.props.value && this.props.value.op === "and") {
      return H.div(null, R(StackedComponent, {
        joinLabel: "and",
        items: _.map(this.props.value.exprs, (function(_this) {
          return function(expr, i) {
            return {
              elem: new ExprElementBuilder(_this.props.schema, _this.props.dataSource, _this.context.locale).build(expr, _this.props.table, _this.handleAndChange.bind(null, i), {
                type: "boolean",
                preferLiteral: false,
                suppressWrapOps: ['and']
              }),
              onRemove: _this.handleAndRemove.bind(null, i)
            };
          };
        })(this))
      }), _.last(this.props.value.exprs) !== null ? this.renderAddFilter() : void 0);
    } else if (this.props.value || this.state.displayNull) {
      return H.div(null, R(RemovableComponent, {
        onRemove: this.handleRemove
      }, new ExprElementBuilder(this.props.schema, this.props.dataSource, this.context.locale).build(this.props.value, this.props.table, this.handleChange, {
        type: "boolean",
        preferLiteral: false,
        suppressWrapOps: ['and']
      })), this.props.value ? this.renderAddFilter() : void 0);
    } else {
      return this.renderAddFilter();
    }
  };

  return FilterExprComponent;

})(React.Component);
