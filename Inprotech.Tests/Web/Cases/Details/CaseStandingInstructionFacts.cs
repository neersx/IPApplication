using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseStandingInstructionFacts : FactBase
    {
        [Theory]
        [InlineData(null, "A", "US", 200)]
        [InlineData(null, null, null, 201)]
        [InlineData(100, "A", "US", 202)]
        [InlineData(null, "A", "US", 203)]
        [InlineData(null, null, "US", 204)]
        public async Task PicksNameInstructionsForCaseId(int? officeNameNum, string propertyTypeId, string countryId, int resultInstrId)
        {
            const int caseId = 100;
            var nameType = Fixture.RandomString(3);
            var instrType = Fixture.RandomString(3);
            const int nameId = 1;
            const short instrIdForCaseId = (short) 200;
            const short instrIdForNullValues = (short) 201;
            const short instrIdForOfficeNo = (short) 202;
            const short instrIdForPropertyType = (short) 203;
            const short instrIdForCountryType = (short) 204;

            var f = new CaseStandingInstructionFixture();

            if (resultInstrId == instrIdForCaseId)
            {
                f.Data.WithNameInstruction(nameId, null, instrIdForCaseId, caseId);
            }

            if (officeNameNum.HasValue)
            {
                f.Data.WithName(officeNameNum.Value);
            }

            f.Data
             .WithCaseDetails(caseId, officeNameNum, propertyTypeId, countryId)
             .WithNameType(nameType)
             .WithName(nameId)
             .WithCaseNamesView(caseId, nameType, officeNameNum ?? nameId)
             .WithInstructionType(instrType, nameType)
             .WithInstruction(instrIdForCaseId, instrType)
             .WithInstruction(instrIdForNullValues, instrType)
             .WithInstruction(instrIdForOfficeNo, instrType)
             .WithInstruction(instrIdForPropertyType, instrType)
             .WithInstruction(instrIdForCountryType, instrType)
             .WithNameInstruction(nameId, null, instrIdForNullValues)
             .WithNameInstruction(officeNameNum ?? 10, null, instrIdForOfficeNo)
             .WithNameInstruction(nameId, null, instrIdForPropertyType, null, propertyTypeId ?? "Someotherproperty")
             .WithNameInstruction(nameId, null, instrIdForCountryType, null, null, countryId ?? "SomeOtherCountry");

            var result = (await f.Subject.GetStandingInstructions(caseId)).ToList();
            Assert.Equal(1, result.Count);
            Assert.Equal(resultInstrId, (int?) result.Single(_ => _.InstructionCode == resultInstrId).InstructionCode);
            Assert.True(result.Any(_ => _.Description == f.Data.Instructions[resultInstrId].Description));
        }

        [Fact]
        public async Task PicksNameInstructionForHomeNameNo()
        {
            const int caseId = 100;
            var nameType = Fixture.RandomString(3);
            var instrType = Fixture.RandomString(3);
            const int nameId = 1;
            const int homeNameNo = 78;
            const short instrId = (short) 200;
            const short instrIdOther = (short) 201;

            var f = new CaseStandingInstructionFixture().WithHomeNameNoSiteControl(homeNameNo);

            f.Data
             .WithCaseDetails(caseId)
             .WithNameType(nameType)
             .WithName(nameId)
             .WithName(homeNameNo)
             .WithCaseNamesView(caseId, nameType, 89) 
             .WithInstructionType(instrType, nameType)
             .WithInstruction(instrId, instrType)
             .WithInstruction(instrIdOther, instrType)
             .WithNameInstruction(nameId, null, instrIdOther)
             .WithNameInstruction(homeNameNo, null, instrId);

            var result = (await f.Subject.GetStandingInstructions(caseId)).ToList();
            Assert.Equal(1, result.Count);
            Assert.Equal(instrId, (int?) result.Single(_ => _.InstructionCode == instrId).InstructionCode);
            Assert.True(result.Any(_ => _.Description == f.Data.Instructions[instrId].Description));
        }

        [Fact]
        public async Task PicksNameInstructionForRestrictedNameTypeIfPresent()
        {
            const int caseId = 100;
            var nameType = Fixture.RandomString(3);
            var restrictedNameType = Fixture.RandomString(3);
            var instrType = Fixture.RandomString(3);
            const int nameId = 1;
            const int restrictedNameId = 10;
            const short instrId = (short) 200;
            const short instrIdOther = (short) 201;

            var f = new CaseStandingInstructionFixture();

            f.Data
             .WithCaseDetails(caseId, nameId)
             .WithNameType(nameType)
             .WithNameType(restrictedNameType, true)
             .WithName(nameId)
             .WithName(restrictedNameId)
             .WithCaseNamesView(caseId, nameType, nameId)
             .WithInstructionType(instrType, nameType, restrictedNameType)
             .WithInstruction(instrId, instrType)
             .WithInstruction(instrIdOther, instrType)
             .WithNameInstruction(nameId, 987, instrId)
             .WithNameInstruction(nameId, restrictedNameId, instrIdOther);

            var result = (await f.Subject.GetStandingInstructions(caseId)).ToList();
            Assert.Equal(0, result.Count);

            f.Data
             .WithCaseNamesView(caseId, restrictedNameType, restrictedNameId);

            result = (await f.Subject.GetStandingInstructions(caseId)).ToList();
            Assert.Equal(1, result.Count);
            Assert.Equal(instrIdOther, (int?) result.Single(_ => _.InstructionCode == instrIdOther).InstructionCode);
            Assert.True(result.Any(_ => _.Description == f.Data.Instructions[instrIdOther].Description));
        }
    }

    public class CaseStandingInstructionFixture : IFixture<ICaseStandingInstructions>
    {
        public CaseStandingInstructionFixture()
        {
            SiteControlReader = Substitute.For<ISiteControlReader>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DbContext = new InMemoryDbContext();

            Subject = new CaseStandingInstructions(DbContext, PreferredCultureResolver, SiteControlReader);
            PreferredCultureResolver.Resolve().Returns(string.Empty);
            Data = new Data(DbContext);
        }

        public CaseStandingInstructionFixture WithHomeNameNoSiteControl(int num)
        {
            SiteControlReader.Read<int>(SiteControls.HomeNameNo).Returns(num);
            return this;
        }

        public ICaseStandingInstructions Subject { get; }
        public ISiteControlReader SiteControlReader { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public InMemoryDbContext DbContext { get; }

        public Data Data { get; }
    }

    public class Data
    {
        readonly InMemoryDbContext _db;

        static int _nameInstrCount = 1;
        
        Dictionary<string, InstructionType> InstructionTypes { get; }

        Dictionary<string, NameType> NameTypes { get; }
        
        public Dictionary<int, Instruction> Instructions { get; }

        public Data(InMemoryDbContext Db)
        {
            _db = Db;

            Instructions = new Dictionary<int, Instruction>();

            InstructionTypes = new Dictionary<string, InstructionType>();

            NameTypes = new Dictionary<string, NameType>();
        }

        NameType BuildNameType(string nameTypeCode, bool isRestricted = false)
        {
            if (NameTypes.TryGetValue(nameTypeCode, out var nameType))
                return nameType;

            NameTypes.Add(nameTypeCode, new NameType {NameTypeCode = nameTypeCode, Name = Fixture.String(), IsNameRestricted = isRestricted ? 1 : 0}.In(_db));

            return NameTypes[nameTypeCode];
        }

        InstructionType BuildInstructionType(string insTypeCode, string nameTypeCode = null, string restrictedByNameType = null)
        {
            if (InstructionTypes.TryGetValue(insTypeCode, out var instructionType))
                return instructionType;

            var instrType = new InstructionType
            {
                Code = insTypeCode,
                RestrictedByTypeCode = restrictedByNameType,
                NameType = string.IsNullOrEmpty(nameTypeCode) ? null : BuildNameType(nameTypeCode),
                RestrictedByType = string.IsNullOrEmpty(restrictedByNameType) ? null : BuildNameType(restrictedByNameType, true)
            }.In(_db);

            InstructionTypes.Add(insTypeCode, instrType);

            return InstructionTypes[insTypeCode];
        }

        void BuildInstruction(short instrId, string instrTypeCode)
        {
            if (Instructions.TryGetValue(instrId, out var _))
                return;

            var instruction = new Instruction
            {
                Id = instrId,
                Description = Fixture.RandomString(10),
                InstructionTypeCode = instrTypeCode,
                InstructionType = BuildInstructionType(instrTypeCode)
            }.In(_db);

            Instructions.Add(instrId, instruction);
        }

        public Data WithCaseDetails(int caseId, int? officeNameNum = null, string propertyTypeId = null, string countryId = null)
        {
            var casePropertyType = string.IsNullOrEmpty(propertyTypeId) ? null : new PropertyTypeBuilder {Id = propertyTypeId}.Build().In(_db);
            var caseOffice = !officeNameNum.HasValue ? null : new Office(officeNameNum.Value, Fixture.RandomString(3)) {OrganisationId = officeNameNum}.In(_db);
            var caseCountry = string.IsNullOrEmpty(countryId) ? null : new CountryBuilder {Id = countryId}.Build().In(_db);
            new CaseBuilder
                    {
                        Office = caseOffice,
                        HasNoDefaultOffice = caseOffice == null,
                        PropertyType = casePropertyType,
                        Country = caseCountry
                    }
                    .BuildWithId(caseId)
                    .In(_db);
            return this;
        }

        public Data WithNameType(string nameTypeCode, bool isRestricted = false)
        {
            BuildNameType(nameTypeCode, isRestricted);
            return this;
        }

        public Data WithName(int nameId)
        {
            new Name(nameId).In(_db);
            return this;
        }

        public Data WithCaseNamesView(int caseId, string nameTypeCode, int nameId)
        {
            new CaseStandingInstructionsNamesView {CaseId = caseId, NameTypeCode = nameTypeCode, NameId = nameId}.In(_db);
            return this;
        }

        public Data WithInstructionType(string insTypeCode, string nameTypeCode, string restrictedByNameType = null)
        {
            BuildInstructionType(insTypeCode, nameTypeCode, restrictedByNameType);
            return this;
        }

        public Data WithInstruction(short instrId, string instrTypeCode)
        {
            BuildInstruction(instrId, instrTypeCode);
            return this;
        }

        public Data WithNameInstruction(int nameNo, int? restrictedToName = null, short? instrId = null, int? caseId = null, string propertyTypeId = null, string countryId = null)
        {
            new NameInstruction
            {
                Id = nameNo,
                Sequence = _nameInstrCount++,
                CaseId = caseId,
                InstructionId = instrId,
                CountryCode = countryId,
                PropertyType = propertyTypeId,
                RestrictedToName = restrictedToName
            }.In(_db);
            return this;
        }
    }
}