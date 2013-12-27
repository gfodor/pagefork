/**
  * @jsx React.DOM
  */

$(function() {
  $(function() {
    $([ { target: "#styles", mode: "text/css", editor: "#cssEditor", component: CssStyles },
        { target: "#html", mode: "text/html", editor: "#htmlEditor", component: HtmlRenderer } ]).each(function() {

      var target = this.target;
      var mode = this.mode;
      var editor = this.editor;
      var component = this.component;

      var codeMirror = CodeMirror.fromTextArea($(editor)[0], { mode: mode });
      var updateContent = function(content) {
        React.renderComponent(
          new component({ content: content }),
          $(target)[0]
        );
      };
      
      updateContent(codeMirror.getValue());

      codeMirror.on("change", function(editor, change) {
        updateContent(editor.getValue());
      });
    });
  });
});
