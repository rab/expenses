/* from:
   http://dev.rubyonrails.org/attachment/ticket/2667/Ajax.InPlaceSelect.3.js?format=raw
   updated by:
   http://www.subzane.com/wp-content/uploads/2006/09/inplaceselect.js

   with refactoring to increase its Rails-ness by Rob Biedenharn
*/
/**
- Ajax.InPlaceSelect.js -

  Creates a <select> control in place of the html element with the id
  specified.  It functions similar to "Ajax.InPlaceEditor" but instead of an
  <input> control, it creates a <select> control with a list of <options> from
  which to choose.  The parameter 'choices' is an array from which the
  <options> are defined.  Each element of 'choices' defines a [label,value]
  pair. (A longer array is treated as [label, ..., value] and as a
  simplification, [label] is equivalent to [label,label] when the value is
  intended to be the same as the label.)  If the element isn't an array, it
  will be used as both label and value.

- Syntax -
  new Ajax.InPlaceSelect('id', 'url', 'choices[][]', { options });

- Example -
  new Ajax.InPlaceSelect('someId', 'someURL', [['first',1], ['second',2]],
    { paramName: 'asset_type', parameters: "moreinfo=extra info" } );

- Options('default value') -
  - onChange(true): when true, the new value is sent when it is changed,
    otherwise, a submit button will be presented (see "okText")
  - okText('ok'): label to use for a submit button (see "onChange: false")
  - cancelLink(true): when true, a link to cancel the select operation
     and restore the original value to the page
  - cancelText('cancel'): label in the cancel link, if present
  - paramName('selected'): name of the default parameter sent
  - clickToEditText('Click to edit'): the text for the title attribute
    which is displayed as a "tool-tip" when hovered
  - hoverClassName(null): class added when mouse hovers over the control
  - hightlightcolor("#FFFF99"): initial color (mouseover)
  - hightlightendcolor("#FFFFFF"): final color (mouseover)
  - savingText('Saving...'): text to display when submitted
  - savingClassName('inplaceeditor-saving'): class added when saving
  - parameters(null): additional parameters to send with the request
      (in addition to the data sent by default)
  - callback: a function

-- Modification History:
- Modified Feb 22, 2006 by Thom Porter (www.thomporter.com)
  - Modified to use Single Click
  - Added "cancelLink" to options - Defaults to true, set to false to not
    show the cancel link
  - Commented the following Lines:
      //this.menu.onblur = this.onCancel.bind(this);
      //this.menu.onmouseout = this.onCancel.bind(this);
    I found that these lines made it switch back when the user would
    mouse off of the select and didn't like that feature. =)

- Modified Feb 25, 2006 by Thom Porter
  - Modified to include callback function.  Function to accept 2
    parameters, value and text.  The first being the value=""
    of the choose option, and the second being the text that
    is displayed.
  - IMPORTANT CHANGE: If you don't provide your own call back
    function, your server-side script should expect the following
    POST variables:
     newval = Value of the chosen <option>
     newtxt = Text of the chosen <option>

- Example using Call Back Function:
  new Ajax.InPlaceSelect('someId', 'someURL', [1,2], ['first','second'],
    {
    	callback: function(value, text) { return 'newval='+value+'&newtxt='+text; }

    } );
  (this example actually does the same things as the default call back function.)


- Modified Sep 21, 2006 by Andreas Norman
  - Added option "okButton" (default true)
  - Added option "okText" (default 'ok')
  - Added option "cancelText" (default 'cancel')
  - Added option to take use of the onChange method or not. (default false)

	- Example using Call Back Function with the new options:
  	new Ajax.InPlaceSelect('someId', 'someURL', [1,2], ['first','second'],
    {
    	okText:'spara', cancelText:'avbryt', callback: function(value, text) { return 'newval='+value+'&newtxt='+text; }

    } );
  - If you have troubles with it to select the correct default value, take note
  	of that the string must match exactly (remove whitespace). If using swedish
  	letters for example, you'll need to convert them to UTF-8.

- Modified Nov 14, 2006 by Jay Buffing
  - I had problems with inplace edit not being able to determine what value
		was already selected.  I added code to strip the spaces first
		and this fixed my problem.

- Modified Feb 22, 2007 by Rob Biedenharn
  - having both onChange and okButton doesn't make sense, if you didn't make a
    change, hit cancel.  Removed okButton and used !onChange in its place.
  - don't strip trailing spaces on initial value (get it right *outside* this code!)

  - change from: new Ajax.InPlaceSelect(element,url,values,labels,options);
             to: new Ajax.InPlaceSelect(element,url,   choices,   options);
    since that works more like the Rails helpers such as options_for_select.
    Therefore, choices is an Array of 2-element Arrays:
    var choices = [ [ label0, value0], ..., [ labelN, valueN ] ];
    It also means that the chance of having a length mismatch between labels
    and values is practically zero (and it should be easier to be aware that
    each element of choices has two [or more] elements).
*/

if ((typeof Prototype == 'undefined') ||
    (typeof Ajax == 'undefined'))
  throw("in_place_select.js requires the Prototype JavaScript framework >= 1.5.0");
if (typeof Builder == 'undefined')
  throw("in_place_select.js requires including script.aculo.us' builder.js library");
if (typeof Effect == 'undefined')
  throw("in_place_select.js requires including script.aculo.us' effect.js library");

Ajax.InPlaceSelect = Class.create();
Ajax.InPlaceSelect.prototype = {
  initialize:function(element,url,choices,options) {
    this.element = $(element);
    this.url = url;
    this.choices = choices;
    this.options = Object.extend({
        onChange: true,
        okText: "ok",
        cancelLink: true,
        cancelText: "cancel",
        clickToEditText: "Click to edit",
        highlightcolor: "#FFFF99",
        highlightendcolor: "#FFFFFF",
        onComplete: function(transport, element) {
          new Effect.Highlight(element, {startcolor: this.options.highlightcolor});
        },
        onFailure: function(transport) {
          alert("Error communicating with the server: " + transport.responseText.stripTags());
        },
        paramName: 'selected',
        callback: function(value, text) {
          return 'newval='+value+'&newtxt='+text;
        },
        savingText: "Saving...",
        savingClassName: 'inplaceeditor-saving'
      }, options || {} );

    this.originalBackground = Element.getStyle(this.element, 'background-color');
    if (!this.originalBackground) {
      this.originalBackground = "transparent";
    }

    this.element.title = this.options.clickToEditText;

    this.ondblclickListener = this.enterEditMode.bindAsEventListener(this);
    this.mouseoverListener = this.enterHover.bindAsEventListener(this);
    this.mouseoutListener = this.leaveHover.bindAsEventListener(this);

    Event.observe(this.element, 'click', this.ondblclickListener);
    Event.observe(this.element, 'mouseover', this.mouseoverListener);
    Event.observe(this.element, 'mouseout', this.mouseoutListener);
  },
  enterEditMode: function(evt) {
    if (this.saving) return;
    if (this.editing) return;
    this.editing = true;
    Element.hide(this.element);
    this.createControls();
    this.element.parentNode.insertBefore(this.menu, this.element);

    if (! this.options.onChange) {
      this.element.parentNode.insertBefore(this.submitButton, this.element);
    }

    if (this.options.cancelLink) {
      this.element.parentNode.insertBefore(this.cancelButton, this.element);
    }
    return false;
  },
  createControls: function() {
    var options = new Array();
    var initial = this.element.innerHTML ;// .replace(/\s*$/, '');

    for (var i=0;i<this.choices.length;i++) {
      var choice = this.choices[i];
      var label = 'fred';
      var value = 'ethel';
      if (choice instanceof Array) {
        label = choice[0];
        value = choice[choice.length-1];
      }
      else {
        label = value = choice;
      }
      options[i] = Builder.node('option',
                                label==initial
                                ? {value:value, selected:'selected'}
                                : {value:value},
                                label);
    }
    this.menu = Builder.node('select', options);

    if (this.options.onChange) {
      this.menu.onchange = this.onChange.bind(this);
    }

    var label = this.element.innerHTML ;// .replace(/\s*$/, '');
    for (var i=0;i<this.choices.length;i++)
      if (this.choices[i][0]==label) {
        this.menu.selectedIndex=i;
        continue;
      }

    if (! this.options.onChange) {
      this.submitButton = Builder.node('button', this.options.okText);
      this.submitButton.onclick = this.onChange.bind(this);
      this.submitButton.className = 'editor_ok_button';
    }

    if (this.options.cancelLink) {
      this.cancelButton = Builder.node('a', this.options.cancelText);
      this.cancelButton.onclick = this.onCancel.bind(this);
      this.cancelButton.className = 'editor_cancel';
    }
  },
  onCancel: function() {
    this.onComplete();
    this.leaveEditMode();
    return false;
  },
  onChange: function() {
    var choice = this.choices[this.menu.selectedIndex];
    var text  = choice[0];
    var value = choice[choice.length-1];
    this.onLoading();
    new Ajax.Updater({
        success:this.element
          },
      this.url,
      Object.extend({
          parameters: this.options.callback(value, text),
            onComplete: this.onComplete.bind(this),
            onFailure: this.onFailure.bind(this)
            }, this.options.ajaxOptions)
      );
  },
  onLoading: function() {
    this.saving = true;
    this.removeControls();
    this.leaveHover();
    this.showSaving();
  },
  removeControls:function() {
    if(this.menu) {
      if (this.menu.parentNode) Element.remove(this.menu);
      this.menu = null;
    }
    if (this.cancelButton) {
      if (this.cancelButton.parentNode) Element.remove(this.cancelButton);
      this.cancelButton = null;
    }
    if (this.submitButton) {
      if (this.submitButton.parentNode) Element.remove(this.submitButton);
      this.submitButton = null;
    }
  },
  showSaving:function() {
    this.oldInnerHTML = this.element.innerHTML;
    this.element.innerHTML = this.options.savingText;
    Element.addClassName(this.element, this.options.savingClassName);
    this.element.style.backgroundColor = this.originalBackground;
    Element.show(this.element);
  },
  onComplete: function() {
    this.leaveEditMode();
    new Effect.Highlight(this.element, {startcolor: this.options.highlightcolor});
    //this.options.onComplete.bind(this)(transport, this.element);
  },
  onFailure: function(transport) {
    this.options.onFailure(transport);
    if (this.oldInnerHTML) {
      this.element.innerHTML = this.oldInnerHTML;
      this.oldInnerHTML = null;
    }
    return false;
  },
  enterHover: function() {
    if (this.saving) return;
    this.element.style.backgroundColor = this.options.highlightcolor;
    if (this.effect) { this.effect.cancel(); }
    Element.addClassName(this.element, this.options.hoverClassName)
  },
  leaveHover: function() {
    if (this.options.backgroundColor) {
      this.element.style.backgroundColor = this.oldBackground;
    }
    Element.removeClassName(this.element, this.options.hoverClassName)
    if (this.saving) return;
    this.effect = new Effect.Highlight(this.element, {
        startcolor: this.options.highlightcolor,
        endcolor: this.options.highlightendcolor,
        restorecolor: this.originalBackground
      });
  },
  leaveEditMode:function(transport) {
    Element.removeClassName(this.element, this.options.savingClassName);
    this.removeControls();
    this.leaveHover();
    this.element.style.backgroundColor = this.originalBackground;
    Element.show(this.element);
    this.editing = false;
    this.saving = false;
    this.oldInnerHTML = null;
  }
}
