<!DOCTYPE html>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html>
<head>
<script
	src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<link rel="stylesheet"
	href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/themes/smoothness/jquery-ui.css">
<script
	src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js"></script>
<link href="<c:url value="/resources/css/main.css" />" rel="stylesheet">
<link href="<c:url value="/resources/css/nouislider.min.css" />"
	rel="stylesheet">
<link href="<c:url value="/resources/css/iThing.css" />"
	rel="stylesheet">
<link
	href="https://gitcdn.github.io/bootstrap-toggle/2.2.0/css/bootstrap-toggle.min.css"
	rel="stylesheet">
<script
	src="https://gitcdn.github.io/bootstrap-toggle/2.2.0/js/bootstrap-toggle.min.js"></script>
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
	




	<c:if test="${!isMain}">
		<input type="checkbox" data-toggle="toggle" data-on="SNAPSHOT"
			data-off="IN" id="checkbox">
		<div id="separador"></div>
		<div id="tooltip"
		style="position: absolute; z-index: 10; visibility: hidden">
		<div id="tooltip-text"></div>
		<div id="tooltip-interval"></div>
		</div>
		<div id="slider"></div>
		<div id="slider_snapshot"></div>
		<div id="outter">
			<div id="graph"></div>
		</div>
		<style>

#separador {
	height: 40px;
}

#slider {
	width: 80%;
	margin: 0 auto;
}

#slider_snapshot {
	width: 80%;
	margin: 0 auto;
}

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

				var formatter = {
					to : function(value) {
						return distinctMoments[value | 0];
					},
					from : function(value) {
						return distinctMoments.indexOf(value);
					}
				};

				var slider = noUiSlider.create(snapSlider, {
					start : [ range['min'], range['max'] ],
					snap : true,
					connect : true,
					tooltips : [ formatter, formatter ],
					range : range
				});

				slider.on('update', function(values, handle) {
					doSlider(values, distinctMoments);
				});
				
				var snapSliderSnapshot = document.getElementById('slider_snapshot');

				var sliderSnapshot = noUiSlider.create(snapSliderSnapshot, {
					start : [range['min']],
					snap : true,
					tooltips : [ formatter ],
					range : range
				});

				sliderSnapshot.on('update', function(values, handle) {
					doSlider(values, distinctMoments);
				});
				$('#slider_snapshot').hide();

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
					svg.selectAll(".node").attr("opacity", "1").each(
							function(d, i) {
								d.clickStatus = false;
							});
					erased = true;
				}
			});
			var node = svg.selectAll(".node").data(graph.nodes).enter().append(
					"circle").attr("class", function(d) {
				return "node " + d.label;
			}).attr("r", 10).call(force.drag).on("mouseover", function(d, i) {
				tooltipText.text(d.name);
				tooltipInterval.text(d.interval);
				tooltip.style("visibility", "visible");
			}).on("click", function(d, i) {
				clickNode = true;
				svg.selectAll(".link").attr("stroke-width", "1.5px");
				svg.selectAll(".node").attr("opacity", "1");
				if (!d.clickStatus || erased) {
					svg.selectAll(".node").each(function(d, i) {
						d.clickStatus = false;
					});
					highlight(i, "4.5px");
					erased = false;
				}
				d.clickStatus = !d.clickStatus;
			}).on(
					"mousemove",
					function() {
						tooltip.style("top", (event.pageY - 10) + "px").style(
								"left", (event.pageX + 10) + "px");
					}).on("mouseout", function(d, i) {
				tooltip.style("visibility", "hidden");
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
			
			$(function() {
				$('#checkbox').change(function() {
					if ($(this).prop('checked')) {
						$('#slider').hide();
						$('#slider_snapshot').show();
						var slider = document.getElementById('slider_snapshot');
						doSlider(slider.noUiSlider.get(), distinctMoments);
					} else {
						$('#slider').show();
						$('#slider_snapshot').hide();
						var slider = document.getElementById('slider');
						doSlider(slider.noUiSlider.get(), distinctMoments);
					}
					
				})
			})

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

				svg.selectAll(".node").filter(function(d, index) {
					return !(index in indexes);
				}).attr("opacity", "0.2");
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
					events = events.concat(moments.map(function(m) {
						return {
							index : ix,
							moment : m
						}
					}));
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
				force.size([ width, height ]).resume();
			};

			function doSlider(interval, map) {
				svg.selectAll(".link").attr("display", "none");
				svg.selectAll(".node").attr("display", "none");
				var visibleNodes = [];
				svg.selectAll(".node").filter(
						function(node) {
							var bool = intervalBelongs([ map[interval[0] | 0],
									map[interval[1] | 0] ], node.interval);
							visibleNodes[node.id] = bool;
							return bool;
						}).attr("display", "block");
				svg.selectAll(".link").filter(
						function(link) {
							return visibleNodes[link.source.id]
									&& visibleNodes[link.target.id];
						}).attr("display", "block");
			}

			function intervalBelongs(interval, testInterval) {
				var start = interval[0];
				var end = interval[1];
				var moments = splitIntervalIntoMoments(testInterval);
				for (var i = 0; i < moments.length / 2; i++) {
					if (start <= moments[2 * i]
							&& (moments[2 * i] <= end || end == 'inf')) {
						return true;
					}

					if (start <= moments[2 * i + 1]
							&& (moments[2 * i + 1] <= end || end == 'inf')) {
						return true;
					}

					if (moments[2 * i] <= start
							&& (end <= moments[2 * i + 1] || moments[2 * i + 1] == 'inf')) {
						return true;
					}
				}

				return false;
			}

			function splitIntervalIntoMoments(interval) {
				var intervals = interval.split("], [");
				var moments = [];
				intervals.forEach(function(i) {
					moments = moments.concat(i.replace("[", "")
							.replace("]", "").split(", "));
				});

				return moments;
			}
		</script>
	</c:if>
</body>
</html>
