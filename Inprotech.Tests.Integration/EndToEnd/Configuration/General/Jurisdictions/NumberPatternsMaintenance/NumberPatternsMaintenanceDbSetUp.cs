using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.NumberPatternsMaintenance
{
    class NumberPatternsMaintenanceDbSetUp : DbSetup
    {
        public const string CountryCode = "c1";
        public const string CountryName = "c1 - country";

        public const string PropertyTypeDesc = "Valid Property";

        public const string CategoryDesc = "Valid Category";

        public const string SubTypeDesc = "Valid SubType";

        public const string InvalidStoredProcName = "nospexist";
        public const string StoredProcName = "cs_Validate_EP_P_A";

        public const string ApplicationNumber = "Application No.";
        public const string AcceptanceNumber = "Acceptance No.";

        public const string Pattern = "abcd";

        public void Prepare()
        {
            var nameStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.NameStyle).Id;
            var addressStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.AddressStyle).Id;
            var country = DbContext.Set<Country>().Add(new Country(CountryCode, CountryName, "0") { PostalName = "c02c02", NameStyleId = nameStyleId, AddressStyleId = addressStyleId });

            var propertyType = DbContext.Set<PropertyType>().First();
            var validPropertyType = new ValidProperty { Country = country, PropertyType = propertyType, PropertyTypeId = propertyType.Code, PropertyName = PropertyTypeDesc };
            DbContext.Set<ValidProperty>().Add(validPropertyType);

            var caseType = DbContext.Set<CaseType>().First(_ => _.Code == "A");
            var caseCategory = DbContext.Set<CaseCategory>().First(_ => _.CaseTypeId == "A");
            var validCaseCategory = new ValidCategory(caseCategory, country, caseType, propertyType, CategoryDesc);
            DbContext.Set<ValidCategory>().Add(validCaseCategory);

            var subType = DbContext.Set<SubType>().First();
            var validSubType = new ValidSubType(validCaseCategory, country, caseType, propertyType, subType) {SubTypeDescription = SubTypeDesc};
            DbContext.Set<ValidSubType>().Add(validSubType);

            InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.OfficialNumberAdditionalValidation, Name = StoredProcName });
            InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.OfficialNumberAdditionalValidation, Name = InvalidStoredProcName });
        }
    }
}
