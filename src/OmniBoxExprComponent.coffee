_ = require 'lodash'
React = require 'react'
R = React.createElement
H = React.DOM
ClickOutHandler = require('react-onclickout')

ScalarExprTreeComponent = require './ScalarExprTreeComponent'
ScalarExprTreeBuilder = require './ScalarExprTreeBuilder'
DropdownComponent = require './DropdownComponent'
LinkComponent = require './LinkComponent'


# Box component that allows selecting if statements, scalars and literals, all in one place
# Has a dropdown when needed and focused.
# It has two modes: literal and formula. If a literal is being edited, it is by default in literal mode
# When in literal mode, 
module.exports = class OmniBoxExprComponent extends React.Component
  @propTypes:
    dataSource: React.PropTypes.object.isRequired # Data source to use to get values

    table: React.PropTypes.string.isRequired # Current table
    value: React.PropTypes.object   # Current expression value
    onChange: React.PropTypes.func  # Called with new expression

    type: React.PropTypes.string    # If specified, the type (value type) of expression required. e.g. boolean
    enumValues: React.PropTypes.array # Array of { id:, name: } of enum values that can be selected. Only when type = "enum"

    noneLabel: React.PropTypes.string # What to display when no value. Default "Select..."
    initialMode: React.PropTypes.oneOf(['formula', 'literal']) # Initial mode. Default formula

    includeCount: React.PropTypes.bool # Optionally include count at root level of a table
    
    enumValues: React.PropTypes.array # Array of { id:, name: } of enum values that can be selected. Only when type = "enum"

  @defaultProps:
    noneLabel: "Select..."
    initialMode: "formula"

  constructor: (props) ->
    super

    @state = {
      focused: false    # True if focused
      mode: props.initialMode  # Mode can be "literal" for literal entering or "formula" for scalar, etc. choosing
      inputText: ""     # Current input text
    }

    # Mode is literal if value is literal
    if props.value and props.value.type == "literal"
      @state.mode = "literal"
      @state.inputText = @stringifyLiteral(props, props.value)

    # Cannot display non-literals
    if props.value and props.value.type != "literal"
      throw new Error("Cannot display expression type #{props.value.type}")

  componentWillReceiveProps: (newProps) ->
    # Mode is literal if value is literal
    if newProps.value and newProps.value.type == "literal"
      @setState(mode: "literal", inputText: @stringifyLiteral(newProps, newProps.value))
    else
      @setState(mode: newProps.initialMode, inputText: "")

    # Cannot display non-literals
    if newProps.value and newProps.value.type != "literal"
      throw new Error("Cannot display expression type #{newProps.value.type}")

  stringifyLiteral: (props, literalExpr) ->
    # Handle enum
    if literalExpr and literalExpr.valueType == "enum"
      item = _.findWhere(props.enumValues, { id: literalExpr.value })
      if item 
        return item.name
      return "???"

    if literalExpr and literalExpr.value?
      return "" + literalExpr.value
    return ""

  handleTextChange: (ev) => @setState(inputText: ev.target.value)

  handleFocus: => 
    @setState(focused: true)

    # Clear input text if literal enum
    if @props.value and @props.value.valueType == "enum"
      @setState(inputText: "")

  handleBlur: => 
    @setState(focused: false)

    # Process literal if present
    if @state.mode == "literal"
      # If text
      if (@props.value and @props.value.valueType == "text") or @props.type == "text"
        @props.onChange({ type: "literal", valueType: "text", value: @state.inputText })
      else if (@props.value and @props.value.valueType == "number") or @props.type == "number"
        # Empty means no value
        if not @state.inputText
          @props.onChange(null)

        value = parseFloat(@state.inputText)
        if _.isFinite(value)
          @props.onChange({ type: "literal", valueType: "number", value: value })

  # Handle enter+tab key
  handleKeyDown: (ev) =>
    if ev.keyCode == 13 or ev.keyCode == 9
      @handleBlur()

  handleEnumSelected: (id) => 
    if id?
      @props.onChange({ type: "literal", valueType: "enum", value: id })
    else
      @props.onChange(null)
    @setState(focused: false)

  # Handle a selection in the scalar expression tree. Called with { table, joins, expr }
  handleTreeChange: (val) => 
    # Loses focus when selection made
    @setState(focused: false)

    # Make into expression
    if val.joins.length == 0 
      # Simple field expression
      @props.onChange(val.expr)
    else
      @props.onChange({ type: "scalar", table: @props.table, joins: val.joins, expr: val.expr })

  handleModeChange: (mode) => 
    # If in formula, clear text
    if mode == "formula"
      @setState(mode: mode, inputText: "", focused: true)
    else 
      @setState(mode: mode, inputText: @stringifyLiteral(@props, @props.value), focused: true)

  # renders mode switching link
  renderModeSwitcher: ->
    # If no value and no type, can't be literal
    if not @props.type and not @props.value
      return

    # If in formula, render literal
    if @state.mode == "formula"
      return H.a(onClick: @handleModeChange.bind(null, "literal"), H.i(null, "abc"))
    else
      return H.a(onClick: @handleModeChange.bind(null, "formula"), H.i(null, "f", H.sub(null, "x")))

  render: ->
    # If focused
    if @state.focused
      # If formula mode, render dropdown scalar
      if @state.mode == "formula"
        # Escape regex for filter string
        escapeRegex = (s) -> return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
        if @state.inputText 
          filter = new RegExp(escapeRegex(@state.inputText), "i")

        # Create tree 
        treeBuilder = new ScalarExprTreeBuilder(@props.schema)
        types = if @props.type then [@props.type]
        tree = treeBuilder.getTree(table: @props.table, types: types, includeCount: @props.includeCount, filter: filter)

        # Create tree component with value of table and path
        dropdown = R ScalarExprTreeComponent, 
          tree: tree,
          onChange: @handleTreeChange
          height: 350

      # If literal 
      if @state.mode == "literal" 
        # If enum type, display dropdown
        if (@props.value and @props.value.valueType == "enum") or (@props.type == "enum")
          # Escape regex for filter string
          escapeRegex = (s) -> return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
          if @state.inputText 
            filter = new RegExp(escapeRegex(@state.inputText), "i")

          dropdown = _.map @props.enumValues, (ev) =>
            if filter and not ev.name.match(filter)
              return null
            H.li key: ev.id, 
              H.a 
                onClick: @handleEnumSelected.bind(null, ev.id),
                ev.name

          # Add none selection
          dropdown.unshift(H.li(key: "_null", H.a(onClick: @handleEnumSelected.bind(null, null), H.i(null, "None"))))

    # Close when clicked outside
    R ClickOutHandler, onClickOut: @handleBlur,
      R DropdownComponent, dropdown: dropdown,
        H.div style: { position: "absolute", right: 10, top: 5, cursor: "pointer" }, @renderModeSwitcher()
        H.input 
          type: "text"
          className: "form-control input-sm"
          style: { width: "40em" }
          ref: @inputRef
          value: @state.inputText
          onFocus: @handleFocus
          onClick: @handleFocus
          onChange: @handleTextChange
          onKeyDown: @handleKeyDown
          placeholder: @props.noneLabel

    

