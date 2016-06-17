var ActionCancelModalComponent, ContentEditableComponent, ExprComponent, ExprInsertModalComponent, ExprUtils, H, InlineExprsEditorComponent, R, React, pasteHtmlAtCaret, select,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

React = require('react');

H = React.DOM;

R = React.createElement;

ExprComponent = require('./ExprComponent');

ExprUtils = require("mwater-expressions").ExprUtils;

select = require('selection-range');

ActionCancelModalComponent = require("react-library/lib/ActionCancelModalComponent");

module.exports = InlineExprsEditorComponent = (function(superClass) {
  extend(InlineExprsEditorComponent, superClass);

  function InlineExprsEditorComponent() {
    this.handleChange = bind(this.handleChange, this);
    this.handleInsert = bind(this.handleInsert, this);
    this.handleInsertClick = bind(this.handleInsertClick, this);
    return InlineExprsEditorComponent.__super__.constructor.apply(this, arguments);
  }

  InlineExprsEditorComponent.propTypes = {
    schema: React.PropTypes.object.isRequired,
    dataSource: React.PropTypes.object.isRequired,
    table: React.PropTypes.string.isRequired,
    text: React.PropTypes.string,
    exprs: React.PropTypes.array,
    onChange: React.PropTypes.func.isRequired,
    multiline: React.PropTypes.bool
  };

  InlineExprsEditorComponent.defaultProps = {
    exprs: []
  };

  InlineExprsEditorComponent.prototype.handleInsertClick = function() {
    return this.refs.insertModal.open();
  };

  InlineExprsEditorComponent.prototype.handleInsert = function(expr) {
    if (expr) {
      return this.refs.contentEditable.pasteHTML(this.createExprHtml(expr), false);
    }
  };

  InlineExprsEditorComponent.prototype.handleChange = function(elem) {
    var exprs, index, processNode, text, wasBr;
    text = "";
    exprs = [];
    wasBr = false;
    index = 0;
    processNode = (function(_this) {
      return function(node, isFirst) {
        var commentNode, i, len, nodeText, ref, ref1, ref2, results, subnode;
        if (node.nodeType === 1) {
          if ((ref = node.tagName) === 'br' || ref === 'BR') {
            text += '\n';
            wasBr = true;
            return;
          }
          if (node.className && node.className.match(/inline-expr-block/)) {
            commentNode = _.find(node.childNodes, function(subnode) {
              return subnode.nodeType === 8;
            });
            if (commentNode) {
              text += "{" + index + "}";
              exprs.push(JSON.parse(decodeURIComponent(commentNode.nodeValue)));
              index += 1;
            }
            return;
          }
          if (!isFirst && !wasBr && ((ref1 = node.tagName) === 'div' || ref1 === 'DIV')) {
            text += "\n";
          }
          wasBr = false;
          ref2 = node.childNodes;
          results = [];
          for (i = 0, len = ref2.length; i < len; i++) {
            subnode = ref2[i];
            results.push(processNode(subnode));
          }
          return results;
        } else if (node.nodeType === 3) {
          wasBr = false;
          nodeText = node.nodeValue;
          if (!_this.props.multiline) {
            nodeText = nodeText.replace(/\r?\n/g, " ");
          }
          return text += nodeText;
        }
      };
    })(this);
    processNode(elem, true);
    text = text.replace(/\u2060/g, '');
    if (!this.props.multiline) {
      text = text.replace(/\r?\n/g, "");
    }
    return this.props.onChange(text, exprs);
  };

  InlineExprsEditorComponent.prototype.createExprHtml = function(expr) {
    var exprUtils, summary;
    exprUtils = new ExprUtils(this.props.schema);
    summary = exprUtils.summarizeExpr(expr);
    if (summary.length > 50) {
      summary = summary.substr(0, 50) + "...";
    }
    return '<div class="inline-expr-block" contentEditable="false"><!--' + encodeURIComponent(JSON.stringify(expr)) + '-->' + _.escape(summary) + '</div>&#x2060;';
  };

  InlineExprsEditorComponent.prototype.createContentEditableHtml = function() {
    var html;
    html = _.escape(this.props.text);
    html = html.replace(/\{(\d+)\}/g, (function(_this) {
      return function(match, index) {
        var expr;
        index = parseInt(index);
        expr = _this.props.exprs[index];
        if (expr) {
          return _this.createExprHtml(expr);
        }
        return "";
      };
    })(this));
    if (this.props.multiline) {
      html = html.replace(/\r?\n/g, "<br>");
    }
    if (html.length === 0) {
      html = '&#x2060;';
    }
    return html;
  };

  InlineExprsEditorComponent.prototype.renderInsertModal = function() {
    return R(ExprInsertModalComponent, {
      ref: "insertModal",
      schema: this.props.schema,
      dataSource: this.props.dataSource,
      table: this.props.table,
      onInsert: this.handleInsert
    });
  };

  InlineExprsEditorComponent.prototype.render = function() {
    return H.div({
      style: {
        position: "relative"
      }
    }, this.renderInsertModal(), H.div({
      style: {
        paddingRight: 20
      }
    }, R(ContentEditableComponent, {
      ref: "contentEditable",
      html: this.createContentEditableHtml(),
      onChange: this.handleChange
    })), H.a({
      onClick: this.handleInsertClick,
      style: {
        cursor: "pointer",
        position: "absolute",
        right: 5,
        top: 8,
        fontStyle: "italic",
        color: "#337ab7"
      }
    }, "f", H.sub(null, "x")));
  };

  return InlineExprsEditorComponent;

})(React.Component);

ExprInsertModalComponent = (function(superClass) {
  extend(ExprInsertModalComponent, superClass);

  ExprInsertModalComponent.propTypes = {
    schema: React.PropTypes.object.isRequired,
    dataSource: React.PropTypes.object.isRequired,
    table: React.PropTypes.string.isRequired,
    onInsert: React.PropTypes.func.isRequired
  };

  function ExprInsertModalComponent() {
    ExprInsertModalComponent.__super__.constructor.apply(this, arguments);
    this.state = {
      open: false,
      expr: null
    };
  }

  ExprInsertModalComponent.prototype.open = function() {
    return this.setState({
      open: true,
      expr: null
    });
  };

  ExprInsertModalComponent.prototype.render = function() {
    if (!this.state.open) {
      return null;
    }
    return R(ActionCancelModalComponent, {
      size: "large",
      actionLabel: "Insert",
      onAction: (function(_this) {
        return function() {
          return _this.setState({
            open: false
          }, function() {
            return _this.props.onInsert(_this.state.expr);
          });
        };
      })(this),
      onCancel: (function(_this) {
        return function() {
          return _this.setState({
            open: false
          });
        };
      })(this),
      title: "Insert Expression"
    }, R(ExprComponent, {
      schema: this.props.schema,
      dataSource: this.props.dataSource,
      table: this.props.table,
      types: ['text', 'number'],
      value: this.state.expr,
      onChange: (function(_this) {
        return function(expr) {
          return _this.setState({
            expr: expr
          });
        };
      })(this)
    }));
  };

  return ExprInsertModalComponent;

})(React.Component);

ContentEditableComponent = (function(superClass) {
  extend(ContentEditableComponent, superClass);

  function ContentEditableComponent() {
    this.handleBlur = bind(this.handleBlur, this);
    this.handleInput = bind(this.handleInput, this);
    return ContentEditableComponent.__super__.constructor.apply(this, arguments);
  }

  ContentEditableComponent.propTypes = {
    html: React.PropTypes.string.isRequired
  };

  ContentEditableComponent.prototype.handleInput = function(ev) {
    if (!this.refs.editor) {
      return;
    }
    return this.props.onChange(this.refs.editor);
  };

  ContentEditableComponent.prototype.handleBlur = function() {
    if (!this.refs.editor) {
      return;
    }
    this.range = select(this.refs.editor);
    return this.props.onChange(this.refs.editor);
  };

  ContentEditableComponent.prototype.pasteHTML = function(html, selectPastedContent) {
    this.refs.editor.focus();
    if (this.range) {
      select(this.refs.editor, this.range);
    }
    pasteHtmlAtCaret(html, selectPastedContent);
    return this.props.onChange(this.refs.editor);
  };

  ContentEditableComponent.prototype.shouldComponentUpdate = function(nextProps) {
    return !this.refs.editor || nextProps.html !== this.refs.editor.innerHTML;
  };

  ContentEditableComponent.prototype.componentWillUpdate = function() {
    return this.range = select(this.refs.editor);
  };

  ContentEditableComponent.prototype.componentDidUpdate = function() {
    if (this.refs.editor && this.props.html !== this.refs.editor.innerHTML) {
      this.refs.editor.innerHTML = this.props.html;
    }
    if (document.activeElement === this.refs.editor) {
      return select(this.refs.editor, this.range);
    }
  };

  ContentEditableComponent.prototype.render = function() {
    return H.div({
      contentEditable: true,
      spellCheck: false,
      ref: "editor",
      style: {
        padding: "6px 12px",
        border: "1px solid #ccc",
        borderRadius: 4
      },
      onInput: this.handleInput,
      onBlur: this.handleBlur,
      dangerouslySetInnerHTML: {
        __html: this.props.html
      }
    });
  };

  return ContentEditableComponent;

})(React.Component);

pasteHtmlAtCaret = function(html, selectPastedContent) {
  var el, firstNode, frag, lastNode, node, originalRange, range, sel;
  sel = void 0;
  range = void 0;
  if (window.getSelection) {
    sel = window.getSelection();
    if (sel.getRangeAt && sel.rangeCount) {
      range = sel.getRangeAt(0);
      range.deleteContents();
      el = document.createElement('div');
      el.innerHTML = html;
      frag = document.createDocumentFragment();
      node = void 0;
      lastNode = void 0;
      while (node = el.firstChild) {
        lastNode = frag.appendChild(node);
      }
      firstNode = frag.firstChild;
      range.insertNode(frag);
      if (lastNode) {
        range = range.cloneRange();
        range.setStartAfter(lastNode);
        if (selectPastedContent) {
          range.setStartBefore(firstNode);
        } else {
          range.collapse(true);
        }
        sel.removeAllRanges();
        sel.addRange(range);
      }
    }
  } else if ((sel = document.selection) && sel.type !== 'Control') {
    originalRange = sel.createRange();
    originalRange.collapse(true);
    sel.createRange().pasteHTML(html);
    if (selectPastedContent) {
      range = sel.createRange();
      range.setEndPoint('StartToStart', originalRange);
      range.select();
    }
  }
};
