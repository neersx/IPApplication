using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public class TableResultSet
    {
        public string Name { get; set; }
        public List<ColumnResultSet> ColumnResultSets { get; set; }
        public List<RowResultSet> RowResultSets { get; set; }
    }
}