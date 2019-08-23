global class PSRadarChartController {
    private static List<String> colors = new List<String> {
        '179,181,198',   // grey
        '128,33,104',    // purple
        '255,99,132',    // pink/red
        '139,69,19',     // saddle brown
        '153,176,0',     // orange
        '0,0,153',       // dark blue
        '153,0,153',     // magenta
        '76,0,153',      // purple
        '0,76,153',      // slate blue
        '0,153,153',     // blue/green
        '0,153,76',      // green
        '153,153,0',     // yellow
        '153,0,0'
    };      // red

    @AuraEnabled
    global static String getData(String configName, String parentId)
    {
        try
        {
            /////////////////////////
            // query configuration //
            /////////////////////////
            PSRadarConfig__c cfg = [SELECT Parent_SObject__c, Child_SObject__c, Child_Label_Field__c, Parent_Lookup_Field__c, Title__c,
                                           Title_Font_Size__c, Trend_Type__c, Min_Value__c, Max_Value__c, Target_Name__c, Filter_Clause__c, Order_By_Clause__c,
                                           (SELECT Field_API_Name__c, Label__c FROM PSRadarConfigField__r ORDER BY Order__c ASC)
                                           FROM PSRadarConfig__c
                                           WHERE Name__c = :configName
                                                    LIMIT 1];
            System.debug(JSON.serializePretty(cfg));


            ////////////////////////////////////////////////////////
            // build dynamic soql string to query for assessments //
            ////////////////////////////////////////////////////////
            String soqlStr = 'SELECT ' + cfg.Child_Label_Field__c;
            for (PSRadarConfigField__c fld : cfg.PSRadarConfigField__r)
            {
                soqlStr += ','  + fld.Field_API_Name__c;
            }
            soqlStr += ' FROM ' + cfg.Child_SObject__c;
            soqlStr += ' WHERE ' + cfg.Parent_Lookup_Field__c + ' = \'' + parentId + '\'';
            if (cfg.Filter_Clause__c != null)
            {
                soqlStr += ' AND ' + cfg.Filter_Clause__c;
            }
            if (cfg.Order_By_Clause__c != null)
            {
                soqlStr += ' ORDER BY ' + cfg.Order_By_Clause__c;
            }
            System.debug(JSON.serializePretty(soqlStr));

            List<SObject> asmtList = Database.query(soqlStr);

            /////////////////////////////////////////////////
            // build data structure for javascript library //
            /////////////////////////////////////////////////
            Map<String, Object> data = new Map<String, Object>();

            // build labels
            List<String> labels = new List<String>();
            for (PSRadarConfigField__c fld : cfg.PSRadarConfigField__r)
            {
                String lbl;
                if (fld.Label__c != null)
                {
                   lbl = fld.Label__c;
                }
                else {
                    lbl = getMetaFieldLabel(cfg.Child_SObject__c, fld.Field_API_Name__c);
                }
                labels.add(lbl);
            }
            data.put('labels', labels);

            // build dataset
            List<Object> datasets = new List<Object>();
            Integer colorIncr = 0;

            for (SObject obj : asmtList)
            {
                String color =  colors[colorIncr];

                Map<String, Object> dataset = new Map<String, Object>();
                dataset.put('label', (String)obj.get(cfg.Child_Label_Field__c));
                dataset.put('fill', true);
                dataset.put('backgroundColor', 'rgba(' + color + ',0.2)');
                dataset.put('borderColor', 'rgba(' + color + ',1)');
                dataset.put('pointBorderColor', '#fff');
                dataset.put('pointBackgroundColor', 'rgba(' + color + ',1)');


                List<Object> valueList = new List<Object>();
                for (PSRadarConfigField__c fld : cfg.PSRadarConfigField__r)
                {
                    valueList.add(obj.get(fld.Field_API_Name__c));
                }
                dataset.put('data', valueList);

                datasets.add(dataset);

                colorIncr++;
            }

            data.put('datasets', datasets);


            //////////////////////////////////////////////
            // create internal section of config params //
            //////////////////////////////////////////////
            Map<String, Object> config = new Map<String, Object>();
            Map<String, Object> scale = new Map<String, Object>();
            scale.put('min', cfg.Min_Value__c);
            scale.put('max', cfg.Max_Value__c);
            config.put('scale', scale);

            if (cfg.Title_Font_Size__c == null)
            {
                cfg.Title_Font_Size__c = 14;
            }
            config.put('title', cfg.Title__c);
            config.put('titleFontSize', cfg.Title_Font_Size__c);
            config.put('trendType', cfg.Trend_Type__c);

            data.put('_config', config);

            /////////////////////////////////////
            // query for merge fields in title //
            /////////////////////////////////////
            List<String> mergeFields = parseMergeFields(cfg.Title__c);
            if (mergeFields != null && mergeFields.size() > 0)
            {
                soqlStr = 'SELECT Id';
                for (String fld : mergeFields)
                {
                    soqlStr += ','  + fld;
                }
                soqlStr += ' FROM ' + cfg.Parent_SObject__c;
                soqlStr += ' WHERE Id = \'' + parentId + '\'';
            }
            List<SObject> mergeQuery = Database.query(soqlStr);
            if (mergeQuery != null && mergeQuery.size() == 1)
            {
                Map<String, Object> mergeFieldsConfig = new Map<String, Object>();
                for (String fld : mergeFields)
                {
                  mergeFieldsConfig.put(fld, mergeQuery[0].get(fld));
                }
                config.put('mergeFields', mergeFieldsConfig);
            }

            System.debug(JSON.serializePretty(data));

            return JSON.serializePretty(data);
        }
        catch (Exception e)
        {
            String err = e.getTypeName() + ' - ' + e.getMessage() + ' [Line: ' + e.getLineNumber() + ']';
            System.debug(err);
            throw new  AuraHandledException(err);
        }

    }

    private static String getMetaFieldLabel(String objtype, String field)
    {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objtype);
        Schema.DescribeSObjectResult sobjResult = targetType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();

        Schema.DescribeFieldResult descField = fieldMap.get(field).getDescribe();
        return descField.getLabel();
    }

    public static List<String> parseMergeFields(String str)
    {
        List<String> mergeFields = new List<String>();

        if (str == null || str.length() == 0)
        {
            return null;
        }

        Boolean startTag = true;
        Integer lastIndex = 0;
        Integer startIndex = -1;
        Integer stopIndex = -1;
        while (true)
        {
            if (startTag)
            {
                startIndex = str.indexOf('{{', lastIndex);
                if (startIndex == -1)
                {
                    break;
                }
                else {
                    startTag = false;
                    startIndex += 2;
                    lastIndex = startIndex;
                }
            }
            else {
                stopIndex = str.indexOf('}}', lastIndex);
                if (stopIndex == -1)
                {
                    break;
                }
                else {
                    startTag = true;
                    lastIndex = stopIndex + 2;
                    mergeFields.add(str.substring(startIndex, stopIndex));
                }
            }
        }

        return mergeFields;
    }
}