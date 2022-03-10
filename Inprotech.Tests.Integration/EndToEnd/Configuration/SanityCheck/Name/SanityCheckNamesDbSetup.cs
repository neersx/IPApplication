using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Name
{
    internal class SanityCheckNamesDbSetup : DbSetup
    {
        string GenerateNewName(string forEntity)
        {
            return $"e2e-{forEntity}-{Fixture.AlphaNumericString(5)}";
        }

        string GenerateNewLongText(string forEntity)
        {
            return $"e2e-{forEntity}-{Fixture.AlphaNumericString(20)}";
        }

        DocItem SetDataItem()
        {
            return new DataItemBuider(DbContext).Create(0, "select * from dbo.cases", GenerateNewName("dataItem"), GenerateNewLongText("DataItemDescription"));
        }

        public NameSanityCheckRuleDetails SetupNamesSanityData()
        {
            var details = new NameSanityCheckRuleDetails
            {
                DataItem = SetDataItem(),
                SanityCheckRule1 = NewWithBasicDetails(1),
                SanityCheckRule2 = NewWithBasicDetails(2),
                SanityCheckRule3 = NewWithBasicDetails(3),
                SanityCheckRule4 = NewWithBasicDetails(4),
                SanityCheckRule5 = NewWithBasicDetails(5)
            };

            details.SanityCheckRule1.InUseFlag = false;
            details.SanityCheckRule1.UsedasFlag = null;

            details.SanityCheckRule2.InUseFlag = true;
            details.SanityCheckRule2.UsedasFlag = null;

            details.SanityCheckRule3.InUseFlag = true;
            details.SanityCheckRule3.UsedasFlag = NameUsedAs.Individual;

            details.SanityCheckRule4.ItemId = details.DataItem.Id;
            details.SanityCheckRule4.InUseFlag = true;
            details.SanityCheckRule4.UsedasFlag = NameUsedAs.StaffMember | NameUsedAs.Individual;

            details.SanityCheckRule5.StatusFlag = 0;

            details.NameCharacteristicsData = SetNameCharacteristics();
            details.Instructions = SetInstructions();

            DbContext.SaveChanges();

            return details;
        }

        DataValidation NewWithBasicDetails(int order)
        {
            return InsertWithNewId(new DataValidation
            {
                FunctionalArea = KnownFunctionalArea.Name,
                DisplayMessage = GenerateNewLongText("DisplayMessage"),
                Notes = GenerateNewLongText("Notes"),
                RuleDescription = GenerateNewLongText($"{order}-Description")
            });
        }

        InstructionsData SetInstructions()
        {
            var nameType = InsertWithNewId(new NameType {Name = GenerateNewName("nameType"), PriorityOrder = 80});
            var instructionType = InsertWithNewId(new InstructionType { Description = GenerateNewName("instruction"), Code = "SE", NameType = nameType});
            var characteristic = new CharacteristicBuilder(DbContext).Create(instructionType.Code, GenerateNewName("characteristics"));

            return new InstructionsData
            {
                InstructionType = instructionType,
                Characteristic = characteristic
            };
        }

        NameCharacteristicsData SetNameCharacteristics()
        {
            var nameGroup = InsertWithNewId(new NameGroup { Value = GenerateNewName("nameGroup") });
            var name = new NameBuilder(DbContext).CreateClientIndividual("e2e");
            var jurisdiction = InsertWithNewId(new Country {Name = GenerateNewName("country"), Type = "1"}, x => x.Id, useAlphaNumeric: true);

            return new NameCharacteristicsData
            {
                Jurisdiction = jurisdiction,
                NameGroup = nameGroup,
                Name = name
            };
        }
    }

    internal class NameSanityCheckRuleDetails
    {
        public DataValidation SanityCheckRule1 { get; set; }

        public DataValidation SanityCheckRule2 { get; set; }

        public DataValidation SanityCheckRule3 { get; set; }

        public DataValidation SanityCheckRule4 { get; set; }

        public DataValidation SanityCheckRule5 { get; set; }

        public NameCharacteristicsData NameCharacteristicsData { get; set; }

        public InstructionsData Instructions { get; set; }

        public DocItem DataItem { get; set; }
    }

    internal class NameCharacteristicsData
    {
        public Country Jurisdiction { get; set; }
        public TableCode Category { get; set; }
        public NameGroup NameGroup { get; set; }
        public InprotechKaizen.Model.Names.Name Name { get; set; }
    }
}