<!DOCTYPE html>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html>
<head>
<link href="<c:url value="/resources/css/main.css" />" rel="stylesheet">
<script src="<c:url value="/resources/js/main.js" />"></script>
<link rel="stylesheet"
	href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<script
	src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script
	src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
<script src="http://d3js.org/d3.v3.min.js" charset="utf-8"></script>
</head>
<body>
	<h1>Neo4j Visualizer</h1>
	<form role="form" action="/query" method="post">
		<div class="form-group">
			<label for="inputlg">Insert Query</label> <input
				class="form-control input-lg" id="inputlg" type="text" name="query">
			<button type="submit" class="btn btn-primary">Submit</button>
		</div>
	</form>
	<c:if test="${!isMain}">
		<div id="graph"></div>
		<style>
.node {
	cursor: pointer;
	stroke: #3182bd;
	stroke-width: 1.5px;
}

.link {
	fill: none;
	stroke: #9ecae1;
	stroke-width: 1.5px;
}
</style>
		<script>
			var width = 800, height = 800;
			var force = d3.layout.force().charge(-200).linkDistance(30).size(
					[ width, height ]);
			var tooltip = d3.select("body").append("div").style("position",
					"absolute").style("z-index", "10").style("visibility",
					"hidden");
			var svg = d3.select("#graph").append("svg").attr("width", "100%")
					.attr("height", "100%").attr("pointer-events", "all");
			var jsonn = '${json}';
			var graph = JSON.parse(jsonn);
			force.nodes(graph.nodes).links(graph.links).start();
			var link = svg.selectAll(".link").data(graph.links).enter().append(
					"line").attr("class", "link");
			var node = svg.selectAll(".node").data(graph.nodes).enter().append(
					"circle").attr("class", function(d) {
				return "node " + d.label;
			}).attr("r", 10).call(force.drag).on("mouseover", function(d) {
				tooltip.text(d.name);
				return tooltip.style("visibility", "visible");
			}).on(
					"mousemove",
					function() {
						return tooltip.style("top", (event.pageY - 10) + "px")
								.style("left", (event.pageX + 10) + "px");
					}).on("mouseout", function() {
				return tooltip.style("visibility", "hidden");
			}).style("fill", color);
			node.append("title").text(function(d) {
				return d.title;
			});
			force.on("tick", function() {
				link.attr("x1", function(d) {
					return d.source.x;
				}).attr("y1", function(d) {
					return d.source.y;
				}).attr("x2", function(d) {
					return d.target.x;
				}).attr("y2", function(d) {
					return d.target.y;
				});
				node.attr("cx", function(d) {
					return d.x;
				}).attr("cy", function(d) {
					return d.y;
				});

			});

			function color(d) {
				return d.label == "Person" ? "#3182bd" : "#fd8d3c";
			}
		</script>
	</c:if>
</body>
</html>
