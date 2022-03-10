using Inprotech.Contracts.Messages;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping
{
    public class MappingFailed : Message
    {
        public string Structure { get; set; }

        public string SystemCode { get; set; }

        public string Description { get; set; } 
    }
}
