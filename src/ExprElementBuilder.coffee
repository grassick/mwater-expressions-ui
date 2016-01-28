_ = require 'lodash'
React = require 'react'
R = React.createElement
H = React.DOM

ExprUtils = require("mwater-expressions").ExprUtils
OmniBoxExprComponent = require './OmniBoxExprComponent'
ExprUtils = require("mwater-expressions").ExprUtils
EnumSetComponent = require './EnumSetComponent'
TextArrayComponent = require './TextArrayComponent'
LinkComponent = require './LinkComponent'
StackedComponent = require './StackedComponent'

module.exports = class ExprElementBuilder 
  constructor: (schema, dataSource, locale) ->
    @schema = schema
    @dataSource = dataSource
    @locale = locale

    @exprUtils = new ExprUtils(@schema)

  # Build the tree for an expression
  # Options include:
  #  types: required value types of expression e.g. ['boolean']
  #  key: key of the resulting element
  #  enumValues: array of { id, name } for the enumerable values to display
  #  idTable: the table from which id-type expressions must come
  #  refExpr: expression to get values for (used for literals). This is primarily for text fields to allow easy selecting of literal values
  #  preferLiteral: to preferentially choose literal expressions (used for RHS of expressions)
  #  suppressWrapOps: pass ops to *not* offer to wrap in
  #  includeCount: true to include count (id) item at root level in expression selector
  build: (expr, table, onChange, options = {}) ->
    # True if a boolean expression is required
    booleanOnly = options.types and options.types.length == 1 and options.types[0] == "boolean" 

    # Create new onChange function. If a boolean type is required and the expression given is not, 
    # it will wrap it with an expression
    innerOnChange = (newExpr) =>
      exprType = @exprUtils.getExprType(newExpr)

      # If boolean and newExpr is not boolean, wrap with appropriate expression
      if booleanOnly and exprType and exprType != "boolean"
        # Find op item that matches
        opItem = @exprUtils.findMatchingOpItems(resultType: "boolean", exprTypes: [exprType])[0]

        if opItem
          # Wrap in op to make it boolean
          newExpr = { type: "op", table: table, op: opItem.op, exprs: [newExpr] }

          # Determine number of arguments to append
          args = opItem.exprTypes.length - 1

          # Add extra nulls for other arguments
          for i in [1..args]
            newExpr.exprs.push(null)

      onChange(newExpr)

    # Get current expression type
    exprType = @exprUtils.getExprType(expr)

    # If text[] or enumset literal, use special component
    if (expr and expr.type == "literal") or (not expr and options.preferLiteral)
      if exprType == "text[]" or _.isEqual(options.types, ["text[]"])
        return R(TextArrayComponent, 
          key: options.key
          value: expr
          refExpr: options.refExpr
          schema: @schema
          dataSource: @dataSource
          onChange: onChange)

      if exprType == "enumset" or _.isEqual(options.types, ["enumset"])
        return R(EnumSetComponent, 
          key: options.key, 
          value: expr, 
          enumValues: options.enumValues
          onChange: onChange)

    # Handle empty and literals with OmniBox
    if not expr or not expr.type or expr.type == "literal"
      elem = R(OmniBoxExprComponent,
        schema: @schema
        table: table
        value: expr
        onChange: innerOnChange
        # Allow any type for boolean due to wrapping
        types: if not booleanOnly then options.types
        # Case statements only when not boolean
        allowCase: not booleanOnly
        enumValues: options.enumValues
        initialMode: if options.preferLiteral then "literal"
        includeCount: options.includeCount
        enumValues: options.enumValues)

    else if expr.type == "op"
      elem = @buildOp(expr, table, innerOnChange, options)
    else if expr.type == "field"
      elem = @buildField(expr, innerOnChange, { key: options.key })
    else if expr.type == "scalar"
      elem = @buildScalar(expr, innerOnChange, { key: options.key, types: options.types })
    else if expr.type == "case"
      elem = @buildCase(expr, innerOnChange, { key: options.key, types: options.types, enumValues: options.enumValues })
    else if expr.type == "id"
      elem = @buildId(expr, innerOnChange, { key: options.key })
    else
      throw new Error("Unhandled expression type #{expr.type}")

    # Wrap element with hover links to build more complex expressions or to clear it
    links = []

    # If boolean, add and/or link
    createWrapOp = (op, name, binaryOnly) =>
      if op not in (options.suppressWrapOps or [])
        # Prevent nesting when simple adding would work
        if expr.op != op or binaryOnly
          links.push({ label: name, onClick: => innerOnChange({ type: "op", op: op, table: table, exprs: [expr, null] }) })
        else
          # Just add extra element
          links.push({ label: name, onClick: => 
            exprs = expr.exprs.slice()
            exprs.push(null)
            innerOnChange(_.extend({}, expr, { exprs: exprs }))
          })

    if exprType == "boolean"
      createWrapOp("and", "+ And", false)
      createWrapOp("or", "+ Or", false)

    if exprType == "number"
      createWrapOp("+", "+", false)
      createWrapOp("-", "-", true)
      createWrapOp("*", "*", false)
      createWrapOp("/", "/", true)

    # Add + If
    if expr and expr.type == "case"
      links.push({ label: "+ If", onClick: => 
        cases = expr.cases.slice()
        cases.push({ when: null, then: null })
        innerOnChange(_.extend({}, expr, { cases: cases }))
      })

    # links.push({ label: "Remove", onClick: => onChange(null) })
    if links.length > 0
      elem = R WrappedLinkComponent, links: links, elem

    return elem

  # Build a simple field component. Only remove option
  buildField: (expr, onChange, options = {}) ->
    return R(LinkComponent, 
      onRemove: => onChange(null),
      @exprUtils.summarizeExpr(expr))    

  # Build an id component. Displays table name. Only remove option
  buildId: (expr, onChange, options = {}) ->
    return R(LinkComponent, 
      dropdownItems: [{ id: "remove", name: "Remove" }]
      onDropdownItemClicked: => onChange(null),
      @exprUtils.summarizeExpr(expr)) 

  # Display aggr if present
  buildScalar: (expr, onChange, options = {}) ->
    # Get aggregations possible on inner expression
    if expr.aggr
      aggrs = @exprUtils.getAggrs(expr.expr)

      # Get current aggr
      aggr = _.findWhere(aggrs, id: expr.aggr)

      aggrElem = R(LinkComponent, 
        dropdownItems: _.map(aggrs, (ag) -> { id: ag.id, name: ag.name }) 
        onDropdownItemClicked: (aggr) =>
          onChange(_.extend({}, expr, { aggr: aggr }))
        , aggr.name)

    # Get joins string
    t = expr.table
    joinsStr = ""
    for join in expr.joins
      joinCol = @schema.getColumn(t, join)
      joinsStr += ExprUtils.localizeString(joinCol.name, @locale) + " > "
      t = joinCol.join.toTable

    # If just a field or id inside, add to string and make a simple link control
    if expr.expr and expr.expr.type in ["field", "id"]
      # Summarize inner
      summary = joinsStr + @exprUtils.summarizeExpr(expr.expr)

      return H.div style: { display: "flex", alignItems: "baseline" },
        # Aggregate dropdown
        aggrElem
        R(LinkComponent, 
          onRemove: => onChange(null)
          summary)
    else
      # Create inner expression onChange
      innerOnChange = (value) =>
        onChange(_.extend({}, expr, { expr: value }))

      # TODO what about count special handling?
      innerElem = @build(expr.expr, (if expr.expr then expr.expr.table), innerOnChange, { types: options.types })

    return H.div style: { display: "flex", alignItems: "baseline" },
      # Aggregate dropdown
      aggrElem
      R(LinkComponent, 
        onRemove: => onChange(null),
        joinsStr)
      innerElem

  # Builds on op component
  buildOp: (expr, table, onChange, options = {}) ->
    switch expr.op
      # For vertical ops (ones with n values or other arithmetic)
      when 'and', 'or', '+', '*', '-', "/"
        # Create inner items
        items = _.map expr.exprs, (innerExpr, i) =>
          # Create onChange that switched single value
          innerElemOnChange = (newValue) =>
            newExprs = expr.exprs.slice()
            newExprs[i] = newValue

            # Set expr value
            onChange(_.extend({}, expr, { exprs: newExprs }))

          types = if expr.op in ['and', 'or'] then ["boolean"] else ["number"]
          elem = @build(innerExpr, table, innerElemOnChange, types: types, suppressWrapOps: [expr.op])
          handleRemove = =>
            exprs = expr.exprs.slice()
            exprs.splice(i, 1)
            onChange(_.extend({}, expr, { exprs: exprs }))          

          return { elem: elem, onRemove: handleRemove }
        
        # Create stacked expression
        R(StackedComponent, joinLabel: expr.op, items: items)
      else
        # Horizontal expression. Render each part
        expr1Type = @exprUtils.getExprType(expr.exprs[0])
        opItem = @exprUtils.findMatchingOpItems(op: expr.op, resultType: options.types, exprTypes: [expr1Type])[0]
        if not opItem
          throw new Error("No opItem defined for op:#{expr.op}, resultType: #{options.types}, lhs:#{expr1Type}")

        lhsOnChange = (newValue) =>
          newExprs = expr.exprs.slice()
          newExprs[0] = newValue

          # Set expr value
          onChange(_.extend({}, expr, { exprs: newExprs }))
        
        lhsElem = @build(expr.exprs[0], table, lhsOnChange, types: [opItem.exprTypes[0]])

        # Special case for between 
        if expr.op == "between"
          rhs1OnChange = (newValue) =>
            newExprs = expr.exprs.slice()
            newExprs[1] = newValue

            # Set expr value
            onChange(_.extend({}, expr, { exprs: newExprs }))

          rhs2OnChange = (newValue) =>
            newExprs = expr.exprs.slice()
            newExprs[2] = newValue

            # Set expr value
            onChange(_.extend({}, expr, { exprs: newExprs }))

          # Build rhs
          rhsElem = [
            @build(expr.exprs[1], table, rhs1OnChange, types: [opItem.exprTypes[1]], enumValues: @exprUtils.getExprEnumValues(expr.exprs[0]), refExpr: expr.exprs[0], preferLiteral: true)
            "\u00A0and\u00A0"
            @build(expr.exprs[2], table, rhs2OnChange, types: [opItem.exprTypes[2]], enumValues: @exprUtils.getExprEnumValues(expr.exprs[0]), refExpr: expr.exprs[0], preferLiteral: true)
          ]
        else if opItem.exprTypes.length > 1 # If has two expressions
          rhsOnChange = (newValue) =>
            newExprs = expr.exprs.slice()
            newExprs[1] = newValue

            # Set expr value
            onChange(_.extend({}, expr, { exprs: newExprs }))

          rhsElem = @build(expr.exprs[1], table, rhsOnChange, types: [opItem.exprTypes[1]], enumValues: @exprUtils.getExprEnumValues(expr.exprs[0]), refExpr: expr.exprs[0], preferLiteral: true)

        # Create op dropdown (finding matching type and lhs, not op)
        opItems = @exprUtils.findMatchingOpItems(resultType: options.types, exprTypes: [expr1Type])

        # Remove current op
        opItems = _.filter(opItems, (oi) -> oi.op != expr.op)
        opElem = R(LinkComponent, 
          dropdownItems: _.map(opItems, (oi) -> { id: oi.op, name: oi.name }) 
          onDropdownItemClicked: (op) =>
            onChange(_.extend({}, expr, { op: op }))
          , opItem.name)

        return H.div style: { display: "flex", alignItems: "baseline", flexWrap: "wrap" },
          lhsElem, opElem, rhsElem

  buildCase: (expr, onChange, options) ->
    # Style for labels "if", "then", "else"
    labelStyle = { 
      flex: "0 0 auto"  # Don't resize
      padding: 5
      color: "#AAA"
    }

    # Create inner elements
    items = _.map expr.cases, (cse, i) =>
      # Create onChange functions
      innerElemOnWhenChange = (newWhen) =>
        cases = expr.cases.slice()
        cases[i] = _.extend({}, cases[i], { when: newWhen })
        onChange(_.extend({}, expr, { cases: cases }))

      innerElemOnThenChange = (newThen) =>
        cases = expr.cases.slice()
        cases[i] = _.extend({}, cases[i], { then: newThen })
        onChange(_.extend({}, expr, { cases: cases }))

      # Build a flexbox that wraps with a when and then flexbox
      elem = H.div key: "#{i}", style: { display: "flex", alignItems: "baseline"  },
        H.div key: "when", style: { display: "flex", alignItems: "baseline" },
          H.div key: "label", style: labelStyle, "if"
          @build(cse.when, expr.table, innerElemOnWhenChange, key: "content", types: ["boolean"], suppressWrapOps: ["if"])
        H.div key: "then", style: { display: "flex", alignItems: "baseline" },
          H.div key: "label", style: labelStyle, "then"
          @build(cse.then, expr.table, innerElemOnThenChange, key: "content", types: options.types, preferLiteral: true, enumValues: options.enumValues)

      handleRemove = =>
        cases = expr.cases.slice()
        cases.splice(i, 1)
        onChange(_.extend({}, expr, { cases: cases })) 

      return { elem: elem, onRemove: handleRemove }
    
    # Add else
    onElseChange = (newValue) =>
      onChange(_.extend({}, expr, { else: newValue }))

    items.push({
      elem: H.div key: "when", style: { display: "flex", alignItems: "baseline" },
        H.div key: "label", style: labelStyle, "else"
        @build(expr.else, expr.table, onElseChange, key: "content", types: options.types, preferLiteral: true, enumValues: options.enumValues)  
    })

    # Create stacked expression
    R(StackedComponent, items: items)

# TODO DOC
class WrappedLinkComponent extends React.Component
  @propTypes:
    links: React.PropTypes.array.isRequired # Shape is label, onClick

  renderLinks: ->
    H.div style: { 
      position: "absolute"
      left: 10
      bottom: 0 
    }, className: "hover-display-child",
      _.map @props.links, (link, i) =>
        H.a key: "#{i}", style: { 
          paddingLeft: 3
          paddingRight: 3
          backgroundColor: "white"
          cursor: "pointer"
          fontSize: 12
        }, onClick: link.onClick,
          link.label

  render: ->
    H.div style: { paddingBottom: 20, position: "relative" }, className: "hover-display-parent",
      H.div style: { 
        position: "absolute"
        height: 10
        bottom: 10
        left: 0
        right: 0
        borderLeft: "solid 1px #DDD" 
        borderBottom: "solid 1px #DDD" 
        borderRight: "solid 1px #DDD" 
      }, className: "hover-display-child"
      @renderLinks(),
        @props.children

