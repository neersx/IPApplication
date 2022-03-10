using System.Collections.Generic;
using InprotechKaizen.Model.Components.DocumentGeneration.Services;

namespace Inprotech.Web.InproDoc.Dto
{
    public class ItemProcessorRequest
    {
        public string ID { get; set; }
        public IList<Field> Fields { get; set; }
        public DocItem DocItem { get; set; }
        public string Separator { get; set; }
        public string Parameters { get; set; }
        public string EntryPointValue { get; set; }
    }
}