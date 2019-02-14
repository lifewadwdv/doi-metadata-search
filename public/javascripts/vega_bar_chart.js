
var spec = {
  "$schema": "https://vega.github.io/schema/vega/v4.json",
  "width": 500,
  "height": 200,
  "padding": 5,

  "data": [],

  "signals": [
    {
      "name": "tooltip",
      "value": {},
      "on": [
        {"events": "rect:mouseover", "update": "datum"},
        {"events": "rect:mouseout",  "update": "{}"}
      ]
    }
  ],

  "scales": [
    {
      "name": "xscale",
      "type": "band",
      "domain": {"data": "iris", "field": "id"},
      "range": "width",
      "padding": 0.05,
      "round": true
    },
    {
      "name": "yscale",
      "domain": {"data": "iris", "field": "sum"},
      "nice": true,
      "range": "height"
    }
  ],

  "axes": [
    { "orient": "bottom", "scale": "xscale", "tickCount": 5 },
    { "orient": "left", "scale": "yscale", "tickCount": 5}
  ],

  "marks": [
    {
      "type": "rect",
      "from": {"data":"iris"},
      "encode": {
        "enter": {
          "x": {"scale": "xscale", "field": "id"},
          "width": {"scale": "xscale", "band": 1},
          "y": {"scale": "yscale", "field": "sum"},
          "y2": {"scale": "yscale", "value": 0}
        },
        "update": {
          "fill": {"value": "gray"}
        },
        "hover": {
          "fill": {"value": "steelblue"}
        }
      }
    },
    {
      "type": "text",
      "encode": {
        "enter": {
          "align": {"value": "center"},
          "baseline": {"value": "bottom"},
          "fill": {"value": "#333"}
        },
        "update": {
          "x": {"scale": "xscale", "signal": "tooltip.id", "band": 0.5},
          "y": {"scale": "yscale", "signal": "tooltip.sum", "offset": -2},
          "text": {"signal": "tooltip.sum"},
          "fillOpacity": [
            {"test": "datum === tooltip", "value": 0},
            {"value": 1}
          ]
        }
      }
    }
  ]
};

var data = [
  {
    "name": "iris",
    "values": []
  }
];

data[0].values= gon.chart_views
spec.data = data;



// uncooment to activate
// $(document).ready(function(e) {
//     vegaEmbed(
//       '#visualisation',
//       spec, {actions: false}
//     );
// });
