<!DOCTYPE html>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html>
<head>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/themes/smoothness/jquery-ui.css">
<script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js"></script>
<link href="<c:url value="/resources/css/main.css" />" rel="stylesheet">
<link href="<c:url value="/resources/css/nouislider.min.css" />" rel="stylesheet">
<link href="<c:url value="/resources/css/iThing.css" />"
	rel="stylesheet">
<script src="<c:url value="/resources/js/main.js" />"></script>
<script src="<c:url value="/resources/js/nouislider.min.js" />"></script>
<link rel="stylesheet"
	href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<script
	src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
<script src="http://d3js.org/d3.v3.min.js" charset="utf-8"></script>

</head>
<body>
	<h1>Neo4j Visualizer</h1>
	<form role="form" action="/query" method="post">
		<div class="form-group">
			<label for="inputlg">Insert Query</label> <input
				class="form-control input-lg" id="inputlg" type="text" name="query"
				value="${query}">
			<button type="submit" class="btn btn-primary">Submit</button>
		</div>
	</form>
	<div id="tooltip"
		style="position: absolute; z-index: 10; visibility: hidden">
		<div id="tooltip-text"></div>
		<div id="tooltip-interval"></div>
	</div>
	
	<input type="text" id="amount" value="40" />
	<div id="slider"></div>
	
	<c:if test="${!isMain}">
	<div id="outter">
		<div id="graph"></div>
	</div>
		<style>
html {
	height: 100%;
}

body {
	height: 100%;
}

div#outter {
height: 100%;
	overflow: auto;
}

div#graph {
	height: 100%;
}

.node {
	cursor: pointer;
	stroke: #3182bd;
	stroke-width: 1.5px;
}

.link {
	fill: none;
	stroke: #9ecae1;
}
</style>
		<script>
			var width = window.innerWidth, height = 1000;
			var clickNode = true;
			var erased = false;
			var force = d3.layout.force().charge(-300).linkDistance(30).size(
					[ width, height ]);
			var svg = d3.select("#graph").append("svg").attr("width", "100%")
					.attr("height", height).attr("pointer-events", "all");
			var tooltip = d3.select("#tooltip");
			var tooltipText = d3.select("#tooltip-text");
			var tooltipInterval = d3.select("#tooltip-interval");
			var jsonn = '${json}';
			var graph = JSON.parse(jsonn);
			var events = getEvents(graph);
			var distinctMoments = getDistinctMoments(events);
			if (events.length > 0) {
				var snapSlider = document.getElementById('slider');
				var range = {};
				range['min'] = 0;
				range['max'] = distinctMoments.length - 1;
				
				for (var r = 1; r < distinctMoments.length - 1; r++) {
					range[r * (100 / (distinctMoments.length - 1)) + '%'] = r;
				}
				
				var formatter  = {
					to: function (value) {
						return distinctMoments[value | 0];
					},
					from: function (value) {
						return distinctMoments.indexOf(value);
					}
				};
				
				var slider = noUiSlider.create(snapSlider, {
					start: [range['min'], range['max']],
					snap: true,
					connect: true,
					tooltips: [formatter, formatter],
					range: range
				});
				
				slider.on('update', function(values, handle) {
					doSlider(values, distinctMoments);
				});
				
				
			}
			var colorMap = {};
			var usedColors = {};
			force.nodes(graph.nodes).links(graph.links).start();
			var link = svg.selectAll(".link").data(graph.links).enter().append(
					"line").attr("class", "link").attr("stroke-width", "1.5px");
			svg.on("click", function(d, i) {
				if (clickNode) {
					clickNode = false;
				} else {
					svg.selectAll(".link").attr("stroke-width", "1.5px");
					svg.selectAll(".node").attr("opacity" , "1").each(function (d, i) {
						d.clickStatus = false;
					});
					erased = true;
				}
			});
			var node = svg.selectAll(".node")
				.data(graph.nodes).enter()
				.append("circle")
				.attr("class", function(d) {return "node " + d.label;})
				.attr("r", 10)
				.call(force.drag)
				.on("mouseover", function(d, i) {
					tooltipText.text(d.name);
					tooltipInterval.text(d.interval);
					tooltip.style("visibility", "visible");
// 					highlight(i, "4.5px");
				})
				.on("click", function(d, i) {
					clickNode = true;
					svg.selectAll(".link").attr("stroke-width", "1.5px");
					svg.selectAll(".node").attr("opacity" , "1");
					if (!d.clickStatus || erased) {
						svg.selectAll(".node").each(function (d, i) {
							d.clickStatus = false;
						});
						highlight(i, "4.5px");
						erased = false;
					}
					d.clickStatus = !d.clickStatus;
				})
				.on("mousemove", function() {
					tooltip
						.style("top", (event.pageY - 10) + "px")
						.style("left", (event.pageX + 10) + "px");
				})
				.on("mouseout", function(d, i) {
					tooltip.style("visibility", "hidden");
				})
				.style("fill", color);
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
			
			function highlight(i, width) {
				var indexes = {};
				svg.selectAll(".link").filter(function(l) {
					var ret = l.source.index == i || l.target.index == i;
					if (ret) {
						indexes[l.source.index] = true;
						indexes[l.target.index] = true;
					}
					return ret;
				}).attr("stroke-width", width);
				
				svg.selectAll(".node").filter(function (d, index) {
					return !(index in indexes);
				}).attr("opacity" , "0.2");
			}

			function color(d) {
				if (d.label == "OBJETO" || d.label == "ARISTA") {
					if (d.name in colorMap) {
						return colorMap[d.name];
					} else {
						var color;
						do {
							color = getRandomColor();
						} while (color in usedColors);
						colorMap[d.name] = color;
						usedColors[color] = true;
						return color;
					}
				}
				if (d.label in colorMap) {
					return colorMap[d.label];
				}
				var color = getRandomColor();
				usedColors[color] = true;
				colorMap[d.label] = color;
				return color;
			}

			function getRandomColor() {
				var letters = '0123456789ABCDEF'.split('');
				var color = '#';
				for (var i = 0; i < 6; i++) {
					color += letters[Math.floor(Math.random() * 16)];
				}
				return color;
			}
			
			function getEvents(graph) {
				var events = [];
				graph.nodes.forEach(function(n, ix) {
					var moments = splitIntervalIntoMoments(n.interval);
					events = events.concat(moments.map(function(m) {return {index: ix, moment: m}}));
				});
				return events.sort(function(e1, e2) {
					if (e1.moment == "inf") {
						if (e2.moment == "inf") {
							return 0;
						}
						
						return 1;
					} else if (e2.moment == "inf") {
						return -1;
					}
					
					return e1.moment - e2.moment;
				});
			}
			
			function getDistinctMoments(orderedEvents) {
				var distinctMoments = [];
				for (var i = 0; i < orderedEvents.length; i++) {
					var event = orderedEvents[i];
					if (distinctMoments.length == 0 
						|| distinctMoments[distinctMoments.length - 1] != event.moment) {
						distinctMoments.push(event.moment);
					}
				}
				
				return distinctMoments;
			}
			window.onresize = function() {
				  width = window.innerWidth;
				  svg.attr('width', width).attr('height', height);
				  force.size([width, height]).resume();
			};
			
			function doSlider(interval, map) {
				svg.selectAll(".link").attr("display", "none");
				svg.selectAll(".node").attr("display", "none");
				
				var graph = {};
				graph.nodes = [];
				graph.links = [];
				
				svg.selectAll(".node").each(function(node) {
					graph.nodes.push(node);
				});
				svg.selectAll(".link").each(function(link) {
					graph.links.push(link);
				});
				
				removeOutOfIntervalPaths(graph, [map[interval[0] | 0], map[interval[1] | 0]]);
				
				var containsWithId = function(arr) {
					return function(elem) {
						for (var xx = 0; xx < graph.nodes.length; xx++ ) {
							if (graph.nodes[xx].id == elem.id) {
								return true;
							}
						}
						return false;
					}
				}
				
				svg.selectAll(".node").filter(containsWithId(graph.nodes)).attr("display", "block");
				svg.selectAll(".link").filter(function(l) {
					return containsWithId(graph.nodes)(l.source) && containsWithId(graph.nodes)(l.target);Aa
				}).attr("display", "block");
			}
			
			function removeOutOfIntervalPaths(graph, interval) {
				var removedNodosArista = [];
				graph.nodes.filter(function(n) {
					return n.label == 'ARISTA';
				}).filter(function(na) {
					return !intervalBelongs(interval, na.interval);
				}).forEach(function(na) {
					removedNodosArista.push(na);
				});
				
				var map = [];
				
				currentConnections = [];
				connected = [];
				
				graph.nodes.filter(function(n) {
					return n.label == 'OBJETO';
				}).forEach(function(no) {
					currentConnections[no.id] = 0;
				});
				
				
				graph.nodes.filter(function(n) {
					return n.label == 'ARISTA';
				}).forEach(function(na) {
					var fromTo = getConnectingNodeIds(na, graph);
					var from = fromTo[0];
					var to = fromTo[1];
					connected[from] = true;
					connected[to] = true;
					currentConnections[from]++;
					currentConnections[to]++;
				});
				
				var xxx = graph.nodes.filter(function(n) {
					return n.label == 'ARISTA';
				});
				
				for (var i = 0; i < removedNodosArista.length; i++) {
					var connectingNodes = getConnectingNodeIds(removedNodosArista[i], graph);
					var from = connectingNodes[0];
					var to = connectingNodes[1];
					var currentArray = map[from];
					if (!currentArray) {
						currentArray = [];
					}
					
					currentArray[to] = true;
					map[from] = currentArray;
					removeNode(removedNodosArista[i], graph, currentConnections, connected);
				}
				
				var nodosArista = graph.nodes.filter(function(n) {
					return n.label == 'ARISTA';
				});
				
				for (i = 0; i < nodosArista.length; i++) {
					var connectingNodes = getConnectingNodeIds(nodosArista[i], graph);
					var from = connectingNodes[0];
					var to = connectingNodes[1];
					var currentArray = map[from];
					if (!currentArray) {
						currentArray = [];
					}
					
					if (currentArray[to]) {
						removeNode(nodosArista[i], graph, currentConnections, connected);
					}
				}
				

				var nodosObjeto = graph.nodes.filter(function(n) {return n.label == 'OBJETO';});
				
				for (i = 0; i < nodosObjeto.length; i++) {
					var no = nodosObjeto[i];
					
					if (!intervalBelongs(interval, no.interval) 
						|| (currentConnections[no.id] == 0 && connected[no.id])) {
						removeNode(nodosObjeto[i], graph);
					}
				}
			}
			
			function getConnectingNodeIds(nodoArista, graph) {
				var nodoAristaId = nodoArista.id;
				var nodeFromId = graph.links.filter(function(l) {return l.source.label == 'OBJETO' && l.target.id == nodoAristaId})[0];
				var nodeToId = graph.links.filter(function(l) {return l.target.label == 'OBJETO' && l.source.id == nodoAristaId})[0];
				
				return [nodeFromId.source.id, nodeToId.target.id];
			}
			
			function indexOf(node, graph) {
				for (var i = 0; i < graph.nodes.length; i++) {
					if (graph.nodes[i].id == node.id) {
						return i;
					}
				}

				return -1;
			}
			
			function removeNode(node, graph, currentConnections, connected) {
				var indexOfNode = indexOf(node, graph);
				
				if (indexOfNode == -1) {
					// Requested to remove a node that was already removed. Do nothing.
					return;
				}
				
				if (node.label == 'OBJETO' && currentConnections && connected) {
					return;
				}
				
				graph.nodes.splice(indexOfNode, 1);
				
				if (node.label == 'VALOR') {
					return;
				}
				
				if (node.label == 'ARISTA') {
					var fromTo = getConnectingNodeIds(node, graph);
					var from = fromTo[0];
					var to = fromTo[1];
					currentConnections[from]--;
					currentConnections[to]--;
				}
				
				var type;
				if (node.label == 'OBJETO') {
					type = 'ATRIBUTO';
				} else if (node.label == 'ARISTA') {
					type = 'ATRIBUTO';
				} else if (node.label == 'ATRIBUTO') {
					type = 'VALOR';
				} else {
					type = '';
				}
				
				removeNodeLinks(node, graph, currentConnections, connected, type);
			}
			
			function removeNodeLinks(node, graph, currentConnections, connected, type) {
				var nodeLinkIndexes = []
				var nodeLinks = function() {
					var ret = [];
					graph.links.forEach(function(link, ix) {
						if (link.source.id == node.id || link.target.id == node.id) {
							nodeLinkIndexes.push(ix);
							ret.push(link);
						}
					});
					
					return ret;
				}();
				
				for (var j = 0; j < nodeLinks.length; j++) {
					graph.links.splice(nodeLinkIndexes[j] - j, 1);
				}
				
				nodeLinks.forEach(function(link) {
					var otherNode = link.source.id == node.id ? link.target : link.source;
					if (otherNode.label == type) {
						removeNode(otherNode, graph, currentConnections, connected);
					}
				});
			}
			
			function intervalBelongs(interval, testInterval) {
				var start = interval[0];
				var end = interval[1];
				var moments = splitIntervalIntoMoments(testInterval);
				for (var i = 0; i < moments.length / 2; i++) {
					if (start <= moments[2 * i] && (moments[2*i] <= end || end == 'inf')) {
						return true;
					}
					
					if (start <= moments[2 * i + 1] && (moments[2*i+1] <= end || end == 'inf')) {
						return true;
					}
					
					if (moments[2*i] <= start && (end <= moments[2 * i + 1] || moments[2 * i + 1] == 'inf')) {
						return true;
					}
				}
				
				return false;
			}
			
			function splitIntervalIntoMoments(interval) {
				var intervals = interval.split("], [");
				var moments = [];
				intervals.forEach(function(i) {
					moments = moments.concat(i.replace("[", "").replace("]", "").split(", "));
				});
				
				return moments;
			}
		</script>
	</c:if>
</body>
</html>
