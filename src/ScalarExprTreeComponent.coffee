React = require 'react'
ReactDOM = require 'react-dom'
H = React.DOM

# Shows a tree that selects table + joins + expr of a scalar expression
module.exports = class ScalarExprTreeComponent extends React.Component 
  @propTypes: 
    tree: React.PropTypes.array.isRequired    # Tree from ScalarExprTreeBuilder
    onChange: React.PropTypes.func.isRequired # Called with newly selected value
    height: React.PropTypes.number.isRequired # Render height of the component

  render: ->
    H.div style: { overflowY: "auto", height: @props.height },
      React.createElement(ScalarExprTreeTreeComponent,
        tree: @props.tree,
        onChange: @props.onChange
        frame: this
      )

class ScalarExprTreeTreeComponent extends React.Component
  @propTypes:
    tree: React.PropTypes.array.isRequired    # Tree from ScalarExprTreeBuilder
    onChange: React.PropTypes.func.isRequired # Called with newly selected value

  render: ->
    elems = []
    # Get tree
    for item, i in @props.tree
      if item.children
        elems.push(
          React.createElement(ScalarExprTreeNodeComponent, key: item.name + "(#{i})", item: item, onChange: @props.onChange))
      else 
        elems.push(
           React.createElement(ScalarExprTreeLeafComponent, key: item.name + "(#{i})", item: item, onChange: @props.onChange))

    H.div null, 
      elems

class ScalarExprTreeLeafComponent extends React.Component
  @propTypes:
    item: React.PropTypes.object.isRequired # Contains item "name" and "value"
  
  handleClick: =>
    @props.onChange(@props.item.value)

  render: ->
    style = {
      padding: 4
      borderRadius: 4
      cursor: "pointer"
      color: "#478"
    }

    H.div style: style, className: "hover-grey-background", onClick: @handleClick, 
      @props.item.name
      if @props.item.desc
        [
          H.br()
          H.span className: "text-muted", style: { fontSize: 12, paddingLeft: 3 }, @props.item.desc
        ]

class ScalarExprTreeNodeComponent extends React.Component
  @propTypes:
    item: React.PropTypes.object.isRequired # Item to display
    onChange: React.PropTypes.func.isRequired # Called when item is selected

  constructor: (props) ->
    super
    @state = { 
      collapse: if @props.item.initiallyOpen then "open" else "closed" 
    }

  handleArrowClick: =>
    if @state.collapse == "open" 
      @setState(collapse: "closed")
    else if @state.collapse == "closed" 
      @setState(collapse: "open")

  handleItemClick: =>
    # If no value, treat as arrow click
    if not @props.item.value
      @handleArrowClick()
    else
      @props.onChange(@props.item.value)      

  render: ->
    arrow = null
    if @state.collapse == "closed"
      arrow = H.span className: "glyphicon glyphicon-triangle-right scalar-arrow"
    else if @state.collapse == "open"
      arrow = H.span className: "glyphicon glyphicon-triangle-bottom scalar-arrow"

    if @state.collapse == "open"
      children = H.div style: { paddingLeft: 25 }, key: "tree",
        React.createElement(ScalarExprTreeTreeComponent, tree: @props.item.children(), onChange: @props.onChange)

    color = if @props.item.value then "#478" 

    H.div null,
      H.div style: { cursor: "pointer", padding: 4 }, key: "arrow",
        H.span style: { color: "#AAA", cursor: "pointer", paddingRight: 3 }, onClick: @handleArrowClick, arrow
        H.span style: { color: color }, onClick: @handleItemClick, @props.item.name
        if @props.item.desc
          [
            H.br()
            H.span className: "text-muted", style: { fontSize: 12, paddingLeft: 3 }, @props.item.desc
          ]
      children
      