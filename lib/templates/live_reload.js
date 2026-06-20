<script>
(function() {
  var ws = new WebSocket('ws://' + location.host + '/__moonblox/events');
  ws.onmessage = function(e) { if (e.data === 'reload') location.reload(); };
  ws.onclose = function() { console.log('[moonblox] live reload disconnected'); };
})();
</script>
</body>
