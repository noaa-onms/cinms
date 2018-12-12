// !preview r2d3 data=read.csv("svg_habitats.csv", strip.white=T)

d3.svg('./img/1b Overview CINMS 2018.svg').then((f) => {
  // https://gist.github.com/mbostock/1014829#gistcomment-2692594
  
  var f_child = svg.node().appendChild(f.documentElement);
  var h = d3.select(f_child);
  
  // resize
  h.attr('width', '100%')
   .attr('height', '100%');
    
  // assign links
  data.forEach(function(d) {
    //console.log('forEach d.id: ' + d.id);
    
    // reset fill in group id and children
    h.selectAll('#' + d.id)
      .style("fill", "black")
      .selectAll("g")
        .style("fill", null)
        .selectAll("path")
          .style("fill", null);
    h.selectAll('#' + d.id + " > path")
      .style("fill", null);

    // handle events
    h.selectAll('#' + d.id)
     .on("click", function() { window.location = d.link;})
     .on("mouseover", handleMouseOver)
     .on("mouseout", handleMouseOut);
     
  }); // end: data.forEach()

});

// handle event functions
function handleMouseOver(d, i) {
  d3.select(this)
    .style("fill", "yellow")
    .style("stroke", "yellow")
    .style("stroke-width", 1);
}
function handleMouseOut(d, i) {
  d3.select(this)
    .style("fill", "black")
    .style("stroke-width", 0);
}



