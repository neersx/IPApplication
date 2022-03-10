using Inprotech.Web.Characteristics;
using Inprotech.Web.Picklists;
using Newtonsoft.Json;
using DateOfLaw = InprotechKaizen.Model.ValidCombinations.DateOfLaw;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Web.Policing
{
    public class CaseAttributes
    {
        public PicklistModel<int> CaseReference { get; set; }

        public PicklistModel<string> Jurisdiction { get; set; }

        public PicklistModel<string> CaseType { get; set; }

        public PicklistModel<int> Office { get; set; }

        public PicklistModel<int> NameType { get; set; }

        public PicklistModel<int> Event { get; set; }

        public dynamic Name { get; set; }

        public dynamic DateOfLaw { get; set; }

        public bool ExcludeAction { get; set; }

        public bool ExcludeJurisdiction { get; set; }

        public bool ExcludeProperty { get; set; }

        public ValidatedCharacteristic PropertyType { get; set; }

        public ValidatedCharacteristic CaseCategory { get; set; }

        public ValidatedCharacteristic SubType { get; set; }

        public ValidatedCharacteristic Action { get; set; }

        [JsonIgnore]
        public Name NameRecord { get; set; }

        [JsonIgnore]
        public DateOfLaw DateOfLawRecord { get; set; }

        [JsonIgnore]
        public InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics RawCharacteristics { get; set; }
    }
 
}