using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Characteristics
{
    public class ValidatedCharacteristic
    {
        public ValidatedCharacteristic(string key = null, string value = null, bool isValid = true)
        {
            Key = key;
            Value = value;
            IsValid = isValid;
            Code = key;
        }

        public bool IsValid { get; set; }
        public string Key { get; set; }
        public string Value { get; set; }
        public string Code { get; set; }
    }

    public class ValidatedCharacteristics
    {
        public ValidatedCharacteristic Office { get; set; }
        public ValidatedCharacteristic CaseType { get; set; }
        public ValidatedCharacteristic Jurisdiction { get; set; }
        public ValidatedCharacteristic PropertyType { get; set; }
        public ValidatedCharacteristic DateOfLaw { get; set; }
        public ValidatedCharacteristic CaseCategory { get; set; }
        public ValidatedCharacteristic SubType { get; set; }
        public ValidatedCharacteristic Basis { get; set; }
        public ValidatedCharacteristic Action { get; set; }
        public ValidatedCharacteristic Program { get; set; }
        public ValidatedCharacteristic Profile { get; set; }
        public ValidatedCharacteristic Checklist { get; set; }

        IEnumerable<ValidatedCharacteristic> ValidCombinationList => new[] { PropertyType, CaseCategory, SubType, Basis, Action, Checklist };

        public bool IsValidCombination => ValidCombinationList.Where(_ => _ != null).All(_ => _.IsValid);
    }
}