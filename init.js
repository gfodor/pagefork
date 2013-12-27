/**
  * @jsx React.DOM
  */

$(function() {
  React.renderComponent(
    <div>
      <JsxEditor />
    </div>,
    $("#content")[0]
  );

  $(function() {
    var cssEditor = CodeMirror.fromTextArea($("#cssEditor")[0], { mode: "css" })

    var updateStyles = function(css) {
      React.renderComponent(
        <CssStyles css={css}/>,
        $("#styles")[0]
      )
    };

    updateStyles(cssEditor.getValue());

    cssEditor.on("change", function(editor, change) {
      updateStyles(cssEditor.getValue());
    });
  });
});
