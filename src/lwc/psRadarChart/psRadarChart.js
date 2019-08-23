import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {loadScript} from 'lightning/platformResourceLoader';
import APP_RESOURCES from '@salesforce/resourceUrl/PSRadarChart';
import getRadarData from '@salesforce/apex/PSRadarChartController.getData';

export default class PsRadarChart extends LightningElement {
  data;
  param;
  myChart;
  myLineChart;
  @api recordId;
  @api configName;

  connectedCallback () {
    var self = this;

    Promise.all ([
      loadScript (this, APP_RESOURCES + '/handlebars-v4.1.2.js'),
      loadScript (this, APP_RESOURCES + '/Chart.js'),
    ]).then (() => {
      //var defaultLegendClickHandler = Chart.defaults.global.legend.onClick;
      var radarLegendClickHandler = function (e, legendItem) {
        //var index = legendItem.datasetIndex;

        //defaultLegendClickHandler (e, legendItem);
        var index = legendItem.datasetIndex;
        var ci = this.chart;
        var meta = ci.getDatasetMeta (index);

        // See controller.isDatasetVisible comment
        meta.hidden = meta.hidden === null
          ? !ci.data.datasets[index].hidden
          : null;

        // We hid a dataset ... rerender the chart
        ci.update ();
      };

      var radarPointClickHandler = function (evt, item) {
        console.log ('onClick...');

        var firstPoint = self.myChart.getElementAtEvent (evt)[0];

        if (firstPoint) {
          var label = self.myChart.data.labels[firstPoint._index];
          var value =
            self.myChart.data.datasets[firstPoint._datasetIndex].data[
              firstPoint._index
            ];
          console.log ('label=' + label);
          console.log ('self.param=' + self.param);

          ////////////////////////////////////////
          // build data JSON for line/bar chart //
          ////////////////////////////////////////
          var idx;
          for (idx = 0; idx < self.data.labels.length; idx++) {
            console.log (self.data.labels[idx]);
            if (self.data.labels[idx] == label) {
              break;
            }
          }

          var data2 = {};
          data2.labels = [];
          data2.datasets = [
            {
              data: [],
              label: label,
              backgroundColor: 'rgba(3, 173, 252, 0.3)',
              borderColor: 'rgba(3,173,252,1)',
              borderWidth: 1,
              fill: true,
            },
          ];
          self.data.datasets.forEach (function (item) {
            data2.labels.push (item.label);
            data2.datasets[0].data.push (item.data[idx]);
          });

          console.log ('data2=' + JSON.stringify (data2));

          if (!self.param) {
            self.param = label;
            self.setLineChart (data2);
            self.template
              .querySelector ('.myLineChart')
              .classList.remove ('hide');
          } else if (label == self.param) {
            self.param = undefined;
            self.template.querySelector ('.myLineChart').classList.add ('hide');
          } else {
            self.param = label;
            self.setLineChart (data2);
          }
        }
      };

      console.log ('getting radar data...');
      getRadarData ({
        configName: this.configName,
        parentId: this.recordId,
      })
        .then (result => {
          console.log ('data=' + result);
          this.data = JSON.parse (result);

          var templateScript = Handlebars.compile (this.data._config.title);
          var title = templateScript (this.data._config.mergeFields);
          console.log ('TITLE=' + title);

          var ctx = this.template
            .querySelector ('.myRadarChart')
            .getContext ('2d');
          self.myChart = new Chart (ctx, {
            type: 'radar',
            data: this.data,
            options: {
              title: {
                display: true,
                fontSize: this.data._config.titleFontSize,
                text: title,
              },
              tooltips: {
                enabled: true,
                callbacks: {
                  label: function (tooltipItem, data) {
                    return (
                      data.datasets[tooltipItem.datasetIndex].label +
                      ' : ' +
                      data.datasets[tooltipItem.datasetIndex].data[
                        tooltipItem.index
                      ]
                    );
                  },
                },
              },
              legend: {
                onClick: radarLegendClickHandler,
              },
              scale: {
                ticks: {
                  min: this.data._config.scale.min,
                  max: this.data._config.scale.max,
                },
              },
              onClick: radarPointClickHandler,
            },
          });

          var lineChart = this.template
            .querySelector ('.myLineChart')
            .getContext ('2d');
          self.myLineChart = new Chart (lineChart, {
            type: this.data._config.trendType,
            data: {},
            options: {
              elements: {
                line: {
                  tension: 0, // disables bezier curves
                },
              },
              scales: {
                yAxes: [
                  {
                    ticks: {
                      min: this.data._config.scale.min,
                      max: this.data._config.scale.max,
                    },
                  },
                ],
              },
            },
          });
        })
        .catch (error => {
          self.handleError(error);
        });
    });
  }

  clearLineChart () {
    this.myLineChart.config.data = {
      labels: [],
      datasets: [],
    };
    this.myLineChart.update ();
  }

  setLineChart (data) {
    this.myLineChart.config.data = data;
    this.myLineChart.update ();
  }

  handleError (err) {
    console.log ('error=' + err);
    console.log ('type=' + typeof err);

    const event = new ShowToastEvent ({
      title: err.statusText,
      message: err.body.message,
      variant: 'error',
      mode: 'pester',
    });
    this.dispatchEvent (event);
  }
}