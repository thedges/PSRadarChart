# PSRadarChart

THIS SOFTWARE IS COVERED BY [THIS DISCLAIMER](https://raw.githubusercontent.com/thedges/Disclaimer/master/disclaimer.txt).

## Component Details

Radar chart demo component for visualizing any assessment type scenarios (health human services, child welfare, general assessments). The component provides the following functionality:
* Can drop on any object page to show radar chart for data in child records. 
* The data to feed the radar chart is assumed to be in child records. For example a correct structure is parent record like Contact and 1-to-many child records like Assessments__c. Each child record would have the numeric parameter values to show in the radar chart. For example, one Assessment__c record could have numeric values for 'Happiness', 'Fitness', 'Health', 'Finances', etc... 
* Can hover over a radar point to get details.
* Click on a radar point and a line/bar chart will show in bottom that shows that metric (i.e. Happiness) over time.

Here is the component in action:

![alt text](https://github.com/thedges/PSRadarChart/blob/master/PSRadarChart.gif "Sample Image")

## Component Configuration

The component has two custom objects used to configure it's capabilities: PSRadarConfig and PSRadarConfigField. Here are the parameters to create for the PSRadarConfig object.

| Parameter | Description |
|-----------|-------------|
| <b>Name</b> | A unique name for this configuration. This will be the name you select when configuring the component in Lightning Page editor.|
| <b>Parent SObject</b> | The API name of the parent object. This is the object page you drop the component on. |
| <b>Child SObject</b> | The API name of the child object that contains the data you will show in radar chart. |
| <b>Child Label Field</b> | The API field name in the child object that include a string to show as the label for that dataset. This field can be a text field user provides...or a formula field if needed.  |
| <b>Parent Lookup Field</b> | The API field name in the child object that provides the lookup/master-detail to parent record. |
| <b>Target Name</b> | This parameter is currently not used. |
| <b>Title</b> | The title to show on the component. You can use a text string like "Assessment for {{FirstName}} {{LastName}}" where the names inside the {{xx}} brackets is a field API name on the parent record (i.e. merge fields). |
| <b>Title Font Size</b> | The font size in pixels for the title (default: 14). |
| <b>Trend Type</b> | The type of chart to show when a radar point is clicked: 'bar' or 'line' are only options. |
| <b>Min Value</b> | The minimum value the radar chart should show. |
| <b>Max Value</b> | The maximum value the radar chart should show. |
| <b>Filter Clause</b> | A SOQL filter clause to filter out child records. For example if your child reocrd had a Type__c field, you could have filter clause value of "Type__c = 'Home Visit' which would only show home visit assessments. |
| <b>Order By Clause</b> | A SOQL order by clause to order the child records in specific order. By default, they will be shown chronologically by CreatedDate field. |

Here are the parameters to create for the PSRadarConfigField child object.

| Parameter | Description |
|-----------|-------------|
| <b>Field API Name</b> | The field API name in child object that contains a metric you want to show in radar chart. |
| <b>Label</b> | [Optional] By default, the component will use the field label to show in chart. You can override the label if needed. |
| <b>Order</b> | [Optional] A number field that you can select the order to show the metrics in radar chart. |

## Component Install and Setup

To use this component:
1. Install the component using the 'Deploy to Salesforce' button below.
2. Assign the 'PSRadarChart' permission set to the users that will use this component.
3. Find the 'PSRadarConfig' tab and create a configuration per the field definitions above. Create 1-to-many child 'PSRadarConfigField' records to define the metrics you want to show in the chart.
4. Drop the 'psRadarChart' component on the record pag you like and in the component configuration, select the name of the configuration definition you created in step #3 above.

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

