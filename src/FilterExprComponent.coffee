_ = require 'lodash'
React = require 'react'
R = React.createElement
H = React.DOM

update = require 'update-object'
ExprCleaner = require("mwater-expressions").ExprCleaner
ExprElementBuilder = require './ExprElementBuilder'

# Displays a boolean filter expression. Just shows "+ Add filter" when empty
module.exports = class FilterExprComponent extends React.Component
  @propTypes:
    schema: React.PropTypes.object.isRequired
    dataSource: React.PropTypes.object.isRequired # Data source to use to get values

    table: React.PropTypes.string.isRequired # Current table

    value: React.PropTypes.object   # Current value
    onChange: React.PropTypes.func  # Called with new expression

  @contextTypes:
    locale: React.PropTypes.string  # e.g. "en"

  constructor: ->
    super

    @state = { displayNull: false } # Set true when initial null value should be displayed

  # Handle add filter clicked by wrapping in "and" if existing, otherwise adding a null
  handleAddFilter: =>
    debugger
    # If already "and", add null
    if @props.value and @props.value.op == "and"
      @props.onChange(update(@props.value, exprs: { $push: [null] }))
      return

    # If already has value, wrap in and
    if @props.value
      @props.onChange({ type: "op", op: "and", table: @props.table, exprs: [@props.value, null] })
      return

    @setState(displayNull: true)

  # Clean expression and pass up
  handleChange: (expr) =>
    # Clean expression
    expr = new ExprCleaner(@props.schema).cleanExpr(expr, {
      table: @props.table
      type: "boolean"
    })

    @props.onChange(expr)

  # Handle change to a single item
  handleAndChange: (i, expr) =>
    @handleChange(update(@props.value, exprs: { $splice: [[i, 1, expr]]}))

  renderAddFilter: ->
    H.div null, 
      H.a onClick: @handleAddFilter, "+ Add Filter"

  render: ->
    # Render each item of and
    if @props.value and @props.value.op == "and"
      return H.div null,
        _.map @props.value.exprs, (expr, i) =>
          new ExprElementBuilder(@props.schema, @props.dataSource, @context.locale).build(expr, @props.table, @handleAndChange.bind(null, i), { 
            type: "boolean"
            preferLiteral: false
            suppressWrapOps: ['and']   # Don't allow wrapping in and since this is an and control
          })
        # Only display add if last item is not null
        if _.last(@props.value.exprs) != null
          @renderAddFilter()

    else if @props.value or @state.displayNull
      return H.div null,
        new ExprElementBuilder(@props.schema, @props.dataSource, @context.locale).build(@props.value, @props.table, @handleChange, { 
          type: "boolean"
          preferLiteral: false
          suppressWrapOps: ['and']  # Don't allow wrapping in and since this is an and control
        })
        # Only display add if has a value
        if @props.value
          @renderAddFilter()

    else
      @renderAddFilter()
