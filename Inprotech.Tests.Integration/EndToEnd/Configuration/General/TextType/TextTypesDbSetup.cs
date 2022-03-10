using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.TextType
{
    public class TextTypesDbSetup : DbSetup
    {
        public const string TextTypeCode = "!";
        public const string TextTypeCode1 = "@";
        public const string TextTypeDescription = "e2e - TextTypes";
        public const string TextTypeToBeAdded = TextTypeDescription + " add";
        public const string TextTypeToBeEdit = TextTypeDescription + " edit";
        public const string TextTypeToBeDuplicate = TextTypeDescription + " duplicate";

        public ScenarioData Prepare()
        {
            var existingTextType = InsertWithNewId(new InprotechKaizen.Model.Cases.TextType
            {
                Id = TextTypeCode,
                TextDescription = TextTypeDescription,
                UsedByFlag = 2
            });
            var protectedTextType = InsertWithNewId(new InprotechKaizen.Model.Cases.TextType
            {
                TextDescription = "Text-protected",
                UsedByFlag = 2
            });
            InsertWithNewId(new ProtectCodes() {TextTypeId = protectedTextType.Id});

            return new ScenarioData
            {
                Code = existingTextType.Id,
                Name = existingTextType.TextDescription,
                UsedByFlag = existingTextType.UsedByFlag,
                ExistingTextType = existingTextType,
            };
        }

        public class ScenarioData
        {
            public string Code;
            public string Name;
            public short? UsedByFlag;
            public InprotechKaizen.Model.Cases.TextType ExistingTextType;

        }

    }
}
