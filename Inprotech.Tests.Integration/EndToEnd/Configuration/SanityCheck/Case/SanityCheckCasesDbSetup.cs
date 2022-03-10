using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.ValidCombinations;
using CaseCategory = InprotechKaizen.Model.Cases.CaseCategory;
using CaseType = InprotechKaizen.Model.Cases.CaseType;
using Name = InprotechKaizen.Model.Names.Name;
using Office = InprotechKaizen.Model.Cases.Office;
using PropertyType = InprotechKaizen.Model.Cases.PropertyType;
using SubType = InprotechKaizen.Model.Cases.SubType;
using StandingInstructions = InprotechKaizen.Model.StandingInstructions;
using Events = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck
{
    internal class SanityCheckCasesDbSetup : DbSetup
    {
        string GenerateNewName(string forEntity) => $"e2e-{forEntity}-{Fixture.AlphaNumericString(5)}";

        string GenerateNewLongText(string forEntity) => $"e2e-{forEntity}-{Fixture.AlphaNumericString(20)}";

        CaseCharacteristicsData SetCaseCharacteristics()
        {
            var office = InsertWithNewId(new Office {Name = GenerateNewName("office")});
            var caseType = InsertWithNewId(new CaseType {Name = GenerateNewName("caseType")}, x => x.Code, useAlphaNumeric: true);
            var jurisdiction = InsertWithNewId(new Country {Name = GenerateNewName("country"), Type = "1"}, x => x.Id, useAlphaNumeric: true);
            var propertyType = InsertWithNewId(new PropertyType {Name = GenerateNewName("propertyType")}, x => x.Code, useAlphaNumeric: true);
            var caseCategory = InsertWithNewId(new CaseCategory {Name = GenerateNewName("caseCategory"), CaseType = caseType}, x => x.CaseCategoryId, useAlphaNumeric: true, maxLength: 2);
            var subType = InsertWithNewId(new SubType {Name = GenerateNewName("subType")}, x => x.Code, useAlphaNumeric: true);
            var basis = InsertWithNewId(new ApplicationBasis {Name = GenerateNewName("basis")}, x => x.Code, useAlphaNumeric: true);

            Insert(new ValidProperty {Country = jurisdiction, PropertyType = propertyType, PropertyName = propertyType.Name});
            var validCategory = Insert(new ValidCategory(caseCategory, jurisdiction, caseType, propertyType, caseCategory.Name){CaseCategoryDesc = caseCategory.Name});
            Insert(new ValidBasis(jurisdiction, propertyType, basis){BasisDescription = basis.Name});
            Insert(new ValidSubType(validCategory, jurisdiction, caseType, propertyType, subType){SubTypeDescription = subType.Name});

            DbContext.SaveChanges();

            return new CaseCharacteristicsData
            {
                Office = office,
                CaseType = caseType,
                PropertyType = propertyType,
                Jurisdiction = jurisdiction,
                CaseCategory = caseCategory,
                SubType = subType,
                Basis = basis,
            };
        }

        NameCharacteristicsData SetNameCharacteristics()
        {
            var nameGroup = InsertWithNewId(new NameGroup {Value = GenerateNewName("nameGroup")});
            var name = new NameBuilder(DbContext).CreateClientIndividual("e2e");
            var nameType = InsertWithNewId(new NameType {Name = GenerateNewName("nameType"), PriorityOrder = 80});
            return new NameCharacteristicsData
            {
                NameGroup = nameGroup,
                Name = name,
                NameType = nameType
            };
        }

        InstructionsData SetInstructions(NameType nameType)
        {
            var instructionType = InsertWithNewId(new StandingInstructions.InstructionType {Description = GenerateNewName("instruction"), Code = "SE", NameType = nameType});
            var characteristic = new CharacteristicBuilder(DbContext).Create(instructionType.Code, GenerateNewName("characteristics"));

            return new InstructionsData
            {
                InstructionType = instructionType,
                Characteristic = characteristic
            };
        }

        Events.Event SetEvents()
        {
            return new EventBuilder(DbContext).Create(GenerateNewName("event"));
        }

        DocItem SetDataItem()
        {
            return new DataItemBuider(DbContext).Create(0, "select * from dbo.cases", GenerateNewName("dataItem"), GenerateNewLongText("DataItemDescription"));
        }

        public CaseSanityCheckRuleDetails SetCaseSanityData()
        {
            var details = new CaseSanityCheckRuleDetails
            {
                CaseCharacteristics = SetCaseCharacteristics(),
                NameCharacteristics = SetNameCharacteristics(),
                EventData = SetEvents(),
                DataItem = SetDataItem(),
                SanityCheckRule1 = NewWithBasicDetails(1),
                SanityCheckRule2 = NewWithBasicDetails(2),
                SanityCheckRule3 = NewWithBasicDetails(3),
                SanityCheckRule4 = NewWithBasicDetails(4),
                SanityCheckRule5 = NewWithBasicDetails(5)
            };
            details.Instructions = SetInstructions(details.NameCharacteristics.NameType);

            details.SanityCheckRule1 = SetWithAllCaseCharacteristics(details.SanityCheckRule1, details.CaseCharacteristics);

            details.SanityCheckRule2 = SetWithAllCaseCharacteristics(details.SanityCheckRule2, details.CaseCharacteristics);
            details.SanityCheckRule2 = SetWithAllNameCharacteristics(details.SanityCheckRule2, details.NameCharacteristics);
            details.SanityCheckRule2.InUseFlag = true;

            details.SanityCheckRule3 = SetWithAllCaseCharacteristics(details.SanityCheckRule3, details.CaseCharacteristics);
            details.SanityCheckRule3 = SetWithAllNameCharacteristics(details.SanityCheckRule3, details.NameCharacteristics);
            details.SanityCheckRule3 = SetWithInstructions(details.SanityCheckRule3, details.Instructions);
            details.SanityCheckRule3.InUseFlag = true;

            details.SanityCheckRule4 = SetWithAllCaseCharacteristics(details.SanityCheckRule4, details.CaseCharacteristics);
            details.SanityCheckRule4 = SetWithAllNameCharacteristics(details.SanityCheckRule4, details.NameCharacteristics);
            details.SanityCheckRule4 = SetWithInstructions(details.SanityCheckRule4, details.Instructions);
            details.SanityCheckRule4.EventNo = details.EventData.Id;
            details.SanityCheckRule4.Eventdateflag = 2;
            details.SanityCheckRule4.ItemId = details.DataItem.Id;
            details.SanityCheckRule4.InUseFlag = true;

            details.SanityCheckRule5 = SetWithAllCaseCharacteristics(details.SanityCheckRule5, details.CaseCharacteristics);
            details.SanityCheckRule5.NotCountryCode = true;
            details.SanityCheckRule5.NotSubtype = true;
            details.SanityCheckRule5.NotBasis = true;
            details.SanityCheckRule5.NotCaseCategory = true;
            details.SanityCheckRule5.NotCaseType = true;
            details.SanityCheckRule5.NotPropertyType = true;
            details.SanityCheckRule5.InUseFlag = true;
            details.SanityCheckRule5.StatusFlag = 0;

            DbContext.SaveChanges();

            return details;
        }

        DataValidation SetWithAllCaseCharacteristics(DataValidation d, CaseCharacteristicsData data)
        {
            d.OfficeId = data.Office.Id;
            d.CaseType = data.CaseType.Code;
            d.CountryCode = data.Jurisdiction.Id;
            d.PropertyType = data.PropertyType.Code;
            d.CaseCategory = data.CaseCategory.CaseCategoryId;
            d.SubType = data.SubType.Code;
            d.Basis = data.Basis.Code;
            d.LocalclientFlag = true;
            d.StatusFlag = 2;

            return d;
        }

        DataValidation SetWithAllNameCharacteristics(DataValidation d, NameCharacteristicsData data)
        {
            d.NameId = data.Name.Id;
            d.NameType = data.NameType.NameTypeCode;

            return d;
        }

        DataValidation SetWithInstructions(DataValidation d, InstructionsData data)
        {
            d.InstructionType = data.InstructionType.Code;
            d.FlagNumber = data.Characteristic.Id;

            return d;
        }

        DataValidation NewWithBasicDetails(int order)
        {
            return InsertWithNewId(new DataValidation
            {
                FunctionalArea = KnownFunctionalArea.Case,
                DisplayMessage = GenerateNewLongText("DisplayMessage"),
                Notes = GenerateNewLongText("Notes"),
                RuleDescription = GenerateNewLongText($"{order}-Description")
            });
        }
    }
}

public class CaseCharacteristicsData
{
    public Office Office { get; set; }
    public CaseType CaseType { get; set; }
    public Country Jurisdiction { get; set; }
    public PropertyType PropertyType { get; set; }
    public CaseCategory CaseCategory { get; set; }
    public SubType SubType { get; set; }
    public ApplicationBasis Basis { get; set; }
}

public class NameCharacteristicsData
{
    public NameGroup NameGroup { get; set; }
    public Name Name { get; set; }
    public NameType NameType { get; set; }
}

public class InstructionsData
{
    public StandingInstructions.InstructionType InstructionType { get; set; }

    public StandingInstructions.Characteristic Characteristic { get; set; }
}

public class CaseSanityCheckRuleDetails
{
    public DataValidation SanityCheckRule1 { get; set; }

    public DataValidation SanityCheckRule2 { get; set; }

    public DataValidation SanityCheckRule3 { get; set; }

    public DataValidation SanityCheckRule4 { get; set; }

    public DataValidation SanityCheckRule5 { get; set; }

    public CaseCharacteristicsData CaseCharacteristics { get; set; }

    public NameCharacteristicsData NameCharacteristics { get; set; }

    public InstructionsData Instructions { get; set; }

    public Events.Event EventData { get; set; }

    public DocItem DataItem { get; set; }
}