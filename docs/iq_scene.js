// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)

d3.xml("img/1b Overview CINMS 2018.svg").mimeType("image/svg+xml").get(function(error, xml) {
  if (error) throw error;
  svg.appendChild(xml.documentElement);
});

/*
svg.append("img")
  //.attr("src","img/1b Overview CINMS 2018.svg")
  .attr("src","http://upload.wikimedia.org/wikipedia/commons/b/b0/NewTux.svg")
  .attr("width", 100)
  .attr("height", 100);
*/