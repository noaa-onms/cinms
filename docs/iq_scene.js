// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)

d3.svg('./img/1b Overview CINMS 2018.svg').then((el) => {
  // https://gist.github.com/mbostock/1014829#gistcomment-2692594
  svg.node().appendChild(el.documentElement);
});
