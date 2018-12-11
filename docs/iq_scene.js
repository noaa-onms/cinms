// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)

// https://bl.ocks.org/mbostock/1014829
d3.xml("./img/1b Overview CINMS 2018.svg").mimeType("image/svg+xml").get(function(error, xml) {
  if (error) throw error;
  //svg.appendChild(xml.documentElement);
  document.getElementById("test").appendChild(xml.documentElement);
  //svg.node().appendChild(xml.documentElement);
});