<pre>
<style type="text/css">
path.link {  fill: none;  stroke: #666;  stroke-width: 1.5px;}
marker#licensing {  fill: green;}
path.link.licensing {  stroke: green;}
path.link.resolved {  stroke-dasharray: 0,2 1;}
circle {  fill: #ccc;  stroke: #333;  stroke-width: 1.5px;}
text {  font: 10px sans-serif;  pointer-events: none;}
text.shadow {  stroke: #fff;  stroke-width: 3px;  stroke-opacity: .8;}
   </style>
<script>
var links = [
  {source: "Microsoft", target: "Amazon", type: "licensing"},
  {source: "Microsoft", target: "HTC", type: "licensing"},
  {source: "Samsung", target: "Apple", type: "suit"},
  {source: "Motorola", target: "Apple", type: "suit"}
  ]
  var nodes = {};
// Compute the distinct nodes from the links.
links.forEach(function(link) {
  link.source = nodes[link.source] || (nodes[link.source] = {name: link.source});
  link.target = nodes[link.target] || (nodes[link.target] = {name: link.target});
});
var width = 960,
    height = 500;
var force = d3.layout.force()
    .nodes(d3.values(nodes))
    .links(links)
    .size([width, height])
    .linkDistance(60)
    .charge(-300)
    .on("tick", tick)
    .start();
var svg = d3.select("body").append("svg").attr("width", width) .attr("height", height); 
var path = svg.append("set").selectAll("path")
    .data(force.links())
    .enter().append("path")
    .attr("class", function(d) { return "path.link.licensing" })
    .attr("marker-end", function(d) { return "url(#" + d.type + ")"; })
var circle = svg.append("set").selectAll("circle")
    .data(force.nodes())
    .enter().append("circle")
    .attr("r", 10)  
    .call(force.drag);
var text = svg.append("set").selectAll("set")
    .data(force.nodes())
  .enter().append("set");

text.append("text")
    .attr("x", 8)
    .attr("y", ".31em")
    .attr("class", "shadow")
    .text(function(d) { return d.name; });

text.append("text")
    .attr("x", 8)
    .attr("y", ".31em")
    .text(function(d) { return d.name; });

function tick() {
  path.attr("d", function(d) {
    var dx = d.target.x - d.source.x,
        dy = d.target.y - d.source.y,
        dr = Math.sqrt(dx * dx + dy * dy);
    return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y;
  });
  circle.attr("transform", function(d) {
    return "translate(" + d.x + "," + d.y + ")";    
  });  
  text.attr("transform", function(d) {
    return "translate(" + d.x + "," + d.y + ")";
  });
}
</script>
</pre>