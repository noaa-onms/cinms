// !preview r2d3 data=read.csv("svg_habitats.csv")

d3.svg('./img/1b Overview CINMS 2018.svg').then((f) => {
  // https://gist.github.com/mbostock/1014829#gistcomment-2692594
  
  var f_child = svg.node().appendChild(f.documentElement);
  var h = d3.select(f_child);
  
  // resize
  h
    .attr('width', '100%')
    .attr('height', '100%');
    
  // assign links
  data.forEach(function(d) {
      var group_selector      = '#' + d.id;
      //var g_children_selector = '#' + d.id + ' path,' + group_selector;
      //var d_link = './modals/' + d.svg_id + '.html';
      //var d_link = d.link;

        if (debug_mode){
          console.log('forEach d...' + d);
          console.log(d);
        }

        // color
        /*d3.selectAll(g_children_selector)
          .style("fill", d.color);

        function highlight(){
          d3.selectAll(g_children_selector).style("stroke", "white");
          d3.selectAll(g_children_selector).style("stroke-width", 1);
        }
        function unhighlight(){
          d3.selectAll(g_children_selector).style("stroke-width", 0);
        }
        function mark_as_visited(){
          d3.selectAll(g_children_selector).style("fill", CLICKED_FILL);
        }*/

        // link each group in svg to modals
        h.selectAll(group_selector)
          //.html(d.link);
          .attr('href', d.link);
          
      }); // end: data.forEach()

});
