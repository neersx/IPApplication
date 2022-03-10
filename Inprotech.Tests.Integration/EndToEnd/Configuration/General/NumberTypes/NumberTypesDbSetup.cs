using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NumberTypes
{
    class NumberTypesDbSetup : DbSetup
    {
        public const string NumberTypeCode = "!";
        public const string NumberTypeCode1 = "@";
        public const string NumberTypeDescription = "e2e - numbertypes";
        public const string NumberTypeToBeAdded = NumberTypeDescription + " add";
        public const string NumberTypeToBeEdit = NumberTypeDescription + " edit";
        public const string NumberTypeToBeDuplicate = NumberTypeDescription + " duplicate";

        public ScenarioData Prepare()
        {
            var existingNumberType = InsertWithNewId(new NumberType
            {
                IssuedByIpOffice = true,
                Name = NumberTypeDescription,
                RelatedEventId = -4
            }, v => v.NumberTypeCode);

            InsertWithNewId(new NumberType
            {
                IssuedByIpOffice = true,
                Name = "Registration No.",
                RelatedEventId = -4
            }, v => v.NumberTypeCode);

            var protectedNumberType = InsertWithNewId(new NumberType
            {
                IssuedByIpOffice = true,
                Name = "e2e - protected",
                RelatedEventId = -4
            }, v => v.NumberTypeCode);

            InsertWithNewId(new ProtectCodes(protectedNumberType.NumberTypeCode));

            return new ScenarioData
            {
                Code = existingNumberType.NumberTypeCode,
                Name = existingNumberType.Name,
                RelatedEvent = existingNumberType.RelatedEventId,
                IssuedByIpOffice = existingNumberType.IssuedByIpOffice,
                ExistingApplicationNumberType = existingNumberType
            };
        }

        public class ScenarioData
        {
            public string Code;
            public string Name;
            public int? RelatedEvent;
            public bool IssuedByIpOffice;
            public NumberType ExistingApplicationNumberType;
        }
    }
}
