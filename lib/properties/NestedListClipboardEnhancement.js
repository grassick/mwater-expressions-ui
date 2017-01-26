var PropertyListEditorComponent, R, React, uuid,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

React = require('react');

R = React.createElement;

uuid = require('uuid');

PropertyListEditorComponent = require('./PropertyListEditorComponent');

module.exports = function(WrappedComponent) {
  var NestedListClipboardEnhancement;
  return NestedListClipboardEnhancement = (function(superClass) {
    extend(NestedListClipboardEnhancement, superClass);

    NestedListClipboardEnhancement.childContextTypes = {
      clipboard: React.PropTypes.object
    };

    function NestedListClipboardEnhancement(props) {
      this.getChildContext = bind(this.getChildContext, this);
      this.handlePaste = bind(this.handlePaste, this);
      this.paste = bind(this.paste, this);
      this.cut = bind(this.cut, this);
      this.handlePasteInto = bind(this.handlePasteInto, this);
      this.handleCopy = bind(this.handleCopy, this);
      this.findItemById = bind(this.findItemById, this);
      this.handleCut = bind(this.handleCut, this);
      NestedListClipboardEnhancement.__super__.constructor.call(this, props);
      this.state = {
        clipboard: null
      };
    }

    NestedListClipboardEnhancement.prototype.handleCut = function(listId, itemId) {
      return this.handleCopy(listId, itemId, true);
    };

    NestedListClipboardEnhancement.prototype.findItemById = function(listId, itemId) {
      var find, found, list, value;
      value = _.cloneDeep(this.props.properties);
      list = _.find(value, {
        id: itemId
      });
      if (list) {
        return list;
      }
      found = null;
      find = function(listId, itemId, items) {
        var i, len, property;
        for (i = 0, len = items.length; i < len; i++) {
          property = items[i];
          if (property.id === listId) {
            return _.find(property.contents, {
              id: itemId
            });
          } else {
            found = find(listId, itemId, _.filter(property.contents, {
              type: "section"
            }));
            if (found) {
              return found;
            }
          }
        }
      };
      return find(listId, itemId, _.filter(value, {
        type: "section"
      }));
    };

    NestedListClipboardEnhancement.prototype.handleCopy = function(listId, itemId, cut) {
      var property, value;
      if (cut == null) {
        cut = false;
      }
      value = _.cloneDeep(this.props.properties);
      property = this.findItemById(listId, itemId);
      if (this.props.propertyIdGenerator) {
        property.id = this.props.propertyIdGenerator();
      }
      return this.setState({
        clipboard: {
          listId: listId,
          itemId: itemId,
          property: property,
          cut: cut
        }
      });
    };

    NestedListClipboardEnhancement.prototype.handlePasteInto = function(listId, itemId) {
      var cutIndex, pasteIndex, pasteInto, value;
      if (!this.state.clipboard) {
        return;
      }
      value = _.cloneDeep(this.props.properties);
      if (this.state.clipboard.cut) {
        cutIndex = _.findIndex(value, {
          id: this.state.clipboard.itemId
        });
        if (cutIndex > -1) {
          _.pullAt(value, cutIndex);
        } else {
          this.cut(this.state.clipboard.listId, this.state.clipboard.itemId, _.filter(value, {
            type: "section"
          }));
        }
      }
      pasteIndex = _.findIndex(value, {
        id: itemId
      });
      if (pasteIndex > -1) {
        if (!value[pasteIndex].contents) {
          value[pasteIndex].contents = [];
        }
        value[pasteIndex].contents.push(this.state.clipboard.property);
      } else {
        pasteInto = (function(_this) {
          return function(listId, itemId, items) {
            var i, len, property, results;
            results = [];
            for (i = 0, len = items.length; i < len; i++) {
              property = items[i];
              if (property.id === listId) {
                pasteIndex = _.findIndex(property.contents, {
                  id: itemId
                });
                if (!property.contents[pasteIndex].contents) {
                  property.contents[pasteIndex].contents = [];
                }
                results.push(property.contents[pasteIndex].contents.push(_this.state.clipboard.property));
              } else {
                results.push(paste(listId, itemId, _.filter(property.contents, {
                  type: "section"
                })));
              }
            }
            return results;
          };
        })(this);
        pasteInto(listId, itemId, _.filter(value, {
          type: "section"
        }));
      }
      this.setState({
        clipboard: null
      });
      return this.props.onChange(value);
    };

    NestedListClipboardEnhancement.prototype.cut = function(listId, itemId, items) {
      var cutIndex, i, len, property, results;
      results = [];
      for (i = 0, len = items.length; i < len; i++) {
        property = items[i];
        if (property.id === listId) {
          cutIndex = _.findIndex(property.contents, {
            id: this.state.clipboard.itemId
          });
          results.push(_.pullAt(property.contents, cutIndex));
        } else {
          results.push(this.cut(listId, itemId, _.filter(property.contents, {
            type: "section"
          })));
        }
      }
      return results;
    };

    NestedListClipboardEnhancement.prototype.paste = function(listId, itemId, items) {
      var i, len, pasteIndex, property, results;
      results = [];
      for (i = 0, len = items.length; i < len; i++) {
        property = items[i];
        if (property.id === listId) {
          pasteIndex = _.findIndex(property.contents, {
            id: itemId
          });
          results.push(property.contents.splice(pasteIndex, 0, this.state.clipboard.property));
        } else {
          results.push(this.paste(listId, itemId, _.filter(property.contents, {
            type: "section"
          })));
        }
      }
      return results;
    };

    NestedListClipboardEnhancement.prototype.handlePaste = function(listId, itemId) {
      var cutIndex, pasteIndex, value;
      if (!this.state.clipboard) {
        return;
      }
      value = _.cloneDeep(this.props.properties);
      if (this.state.clipboard.cut) {
        cutIndex = _.findIndex(value, {
          id: this.state.clipboard.itemId
        });
        if (cutIndex > -1) {
          _.pullAt(value, cutIndex);
        } else {
          this.cut(this.state.clipboard.listId, this.state.clipboard.itemId, _.filter(value, {
            type: "section"
          }));
        }
      }
      pasteIndex = _.findIndex(value, {
        id: itemId
      });
      if (pasteIndex > -1) {
        value.splice(pasteIndex, 0, this.state.clipboard.property);
      } else {
        this.paste(listId, itemId, _.filter(value, {
          type: "section"
        }));
      }
      this.setState({
        clipboard: null
      });
      return this.props.onChange(value);
    };

    NestedListClipboardEnhancement.prototype.getChildContext = function() {
      return {
        clipboard: this.state.clipboard
      };
    };

    NestedListClipboardEnhancement.prototype.render = function() {
      var newProps;
      newProps = {
        onCut: this.handleCut,
        onCopy: this.handleCopy,
        onPaste: this.handlePaste,
        onPasteInto: this.handlePasteInto
      };
      return R(WrappedComponent, _.assign({}, this.props, newProps));
    };

    return NestedListClipboardEnhancement;

  })(React.Component);
};
