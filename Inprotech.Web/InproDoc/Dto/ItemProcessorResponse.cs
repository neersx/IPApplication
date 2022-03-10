using System.Collections.Generic;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;

namespace Inprotech.Web.InproDoc.Dto
{
    public class ItemProcessorResponse
    {
        public string ID { get; set; }
        public int DateStyle { get; set; }
        public string EmptyValue { get; set; }
        public IList<TableResultSet> TableResultSets { get; set; }
        public string Exception { get; set; }
    }
}