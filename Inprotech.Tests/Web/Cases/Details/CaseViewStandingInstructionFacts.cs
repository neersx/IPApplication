using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewStandingInstructionFacts : FactBase
    {
        [Fact]
        public async Task ReturnStandingInstructionsWithAnnualAndFortnightly()
        {
            const int caseId = 100;
            const int nameNo = 4567;
            const int nameId = 1234;
            const string instrTypeB = "B";
            const string instrTypeC = "C";
            var nameType1 = Fixture.RandomString(3);
            var nameType2 = Fixture.RandomString(3);
            const short instrIdForNullValues = 201;
            const short instrIdForOfficeNo = 202;
            var instructions = new[]
            {
                new CompositeInstruction {CompositeCode = "1234       1          1234       ", InstructionTypeCode = instrTypeB},
                new CompositeInstruction {CompositeCode = "1234       2          1234       ", InstructionTypeCode = instrTypeC}
            };

            var country = new Country("1", "Aus") {WorkDayFlag = 124};
            var f = new CaseViewStandingInstructionFixture().WithHomeCountrySiteControl(country).WithUser(false);

            f.WithCaseStandingInstructions(instructions)
             .Data
             .WithCaseDetails(caseId)
             .WithAdjustments()
             .WithTableCodes()
             .WithNameType(nameType1)
             .WithNameType(nameType2)
             .WithInstructionType(instrTypeB, nameType2)
             .WithInstructionType(instrTypeC, nameType1)
             .WithName(nameNo)
             .WithName(nameId)
             .WithInstruction(instrIdForNullValues, instrTypeB)
             .WithInstruction(instrIdForOfficeNo, instrTypeC)
             .WithNameInstruction(nameId, 1, instrIdForNullValues, caseId, Fixture.String(), DateTime.Now.AddDays(-9),
                                  adjustment: KnownAdjustment.Annual, adjustmentDay: 12, adjustStartMonth: 1, adjustDayOfWeek: 2)
             .WithNameInstruction(nameId, 2, instrIdForOfficeNo, caseId, Fixture.String(), DateTime.Now.AddDays(-8),
                                  adjustment: KnownAdjustment.Fortnightly, adjustmentDay: 15, adjustStartMonth: 3, adjustDayOfWeek: 3);

            var result = (await f.Subject.GetCaseStandingInstructions(caseId)).ToList();
            Assert.Equal(2, result.Count);

            var instruction1 = result.Single(_ => _.InstructionTypeCode == instrTypeB);

            Assert.Equal(12, instruction1.AdjustDay);
            Assert.Equal("ab", instruction1.AdjustStartMonth);
            Assert.True(instruction1.ShowAdjustDay);
            Assert.True(instruction1.ShowAdjustStartMonth);
            Assert.False(instruction1.ShowAdjustDayOfWeek);
            Assert.False(instruction1.ShowAdjustToDate);

            var instruction2 = result.Single(_ => _.InstructionTypeCode == instrTypeC);

            Assert.Equal("ijk", instruction2.AdjustDayOfWeek);
            Assert.False(instruction2.ShowAdjustDay);
            Assert.False(instruction2.ShowAdjustStartMonth);
            Assert.True(instruction2.ShowAdjustDayOfWeek);
            Assert.False(instruction2.ShowAdjustToDate);
        }

        [Fact]
        public async Task ReturnStandingInstructionsWithNameNoAndUserDate()
        {
            const int caseId = 100;
            const int nameNo = 4567;
            const int nameId = 1234;
            const string instrTypeB = "B";
            const string instrTypeC = "C";
            const string instrTypeD = "D";
            var nameType1 = Fixture.RandomString(3);
            var nameType2 = Fixture.RandomString(3);
            const short instrIdForNullValues = 201;
            const short instrIdForOfficeNo = 202;
            const short instrIdForPropertyType = 203;
            var instructions = new[]
            {
                new CompositeInstruction {CompositeCode = "4567       1          1234       ", InstructionTypeCode = instrTypeB},
                new CompositeInstruction {CompositeCode = "1234       2          1234       ", InstructionTypeCode = instrTypeC},
                new CompositeInstruction {CompositeCode = "1234       3          1234       ", InstructionTypeCode = instrTypeD}
            };

            var country = new Country("1", "Aus") {WorkDayFlag = 124};
            var f = new CaseViewStandingInstructionFixture().WithHomeCountrySiteControl(country).WithUser(false);

            f.WithCaseStandingInstructions(instructions)
             .Data
             .WithCaseDetails(caseId)
             .WithAdjustments()
             .WithTableCodes()
             .WithNameType(nameType1)
             .WithNameType(nameType2)
             .WithInstructionType(instrTypeB, nameType2)
             .WithInstructionType(instrTypeC, nameType1)
             .WithInstructionType(instrTypeD, nameType2)
             .WithName(nameNo)
             .WithName(nameId)
             .WithInstruction(instrIdForNullValues, instrTypeB)
             .WithInstruction(instrIdForOfficeNo, instrTypeC)
             .WithInstruction(instrIdForPropertyType, instrTypeD)
             .WithNameInstruction(nameNo, 1, instrIdForNullValues, caseId, Fixture.String(), DateTime.Now.AddDays(-9), null, null, null, null, null, null, KnownAdjustment.Annual, 12, 1, 2)
             .WithNameInstruction(nameId, 2, instrIdForOfficeNo, caseId, Fixture.String(), DateTime.Now.AddDays(-8), null, null, null, null, null, null, KnownAdjustment.Fortnightly, 15, 3, 3)
             .WithNameInstruction(nameId, 3, instrIdForPropertyType, caseId, Fixture.String(), DateTime.Now.AddDays(-3), null, null, null, null, null, null, KnownAdjustment.UserDate, 14, 5, 5);

            var result = (await f.Subject.GetCaseStandingInstructions(caseId)).ToList();
            Assert.Equal(3, result.Count);

            var instruction1 = result.Single(_ => _.InstructionTypeCode == instrTypeB);
            Assert.Equal(nameNo, instruction1.NameNo);

            var instruction2 = result.Single(_ => _.InstructionTypeCode == instrTypeD);
            Assert.Equal($"{DateTime.Now.AddDays(-3):dd/MM/yyyy}", $"{instruction2.AdjustToDate:dd/MM/yyyy}");
            Assert.False(instruction2.ShowAdjustDay);
            Assert.False(instruction2.ShowAdjustStartMonth);
            Assert.False(instruction2.ShowAdjustDayOfWeek);
            Assert.True(instruction2.ShowAdjustToDate);
        }

        [Fact]
        public async Task ReturnStandingInstructionsWithPeriods()
        {
            const int caseId = 100;
            const int nameId = 1234;
            const string instrTypeA = "A";
            var nameType1 = Fixture.RandomString(3);
            const short instrIdForCaseId = 101;
            var instructions = new[]
            {
                new CompositeInstruction {CompositeCode = "1234       1          1234       ", InstructionTypeCode = instrTypeA}
            };

            var country = new Country("1", "Aus") {WorkDayFlag = 124};
            var f = new CaseViewStandingInstructionFixture().WithHomeCountrySiteControl(country).WithUser(false);

            f.WithCaseStandingInstructions(instructions)
             .Data
             .WithCaseDetails(caseId)
             .WithAdjustments()
             .WithTableCodes()
             .WithNameType(nameType1)
             .WithInstructionType(instrTypeA, nameType1)
             .WithName(nameId)
             .WithInstruction(instrIdForCaseId, instrTypeA)
             .WithNameInstruction(nameId, 1, instrIdForCaseId, caseId, Fixture.String(), null, 1, "d", 2, "w", 3, "m");

            var result = (await f.Subject.GetCaseStandingInstructions(caseId)).ToList();
            Assert.Equal(1, result.Count);

            var instruction = result.Single(_ => _.InstructionTypeCode == instrTypeA);
            Assert.NotNull(instruction.Period1Amt);
            Assert.NotNull(instruction.Period1Type);
            Assert.Equal("week", instruction.Period2Type);
        }
    }

    public class CaseViewStandingInstructionFixture : IFixture<ICaseViewStandingInstructions>
    {
        public CaseViewStandingInstructionFixture()
        {
            SiteConfiguration = Substitute.For<ISiteConfiguration>();
            SecurityContext = Substitute.For<ISecurityContext>();
            StandingInstructions = Substitute.For<ICaseStandingInstructions>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DbContext = new InMemoryDbContext();

            Subject = new CaseViewStandingInstructions(DbContext, PreferredCultureResolver, SiteConfiguration, SecurityContext, StandingInstructions);
            PreferredCultureResolver.Resolve().Returns(string.Empty);
            Data = new FakeData(DbContext);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public InMemoryDbContext DbContext { get; }

        public ISiteConfiguration SiteConfiguration { get; }

        public ISecurityContext SecurityContext { get; }
        public FakeData Data { get; }

        public ICaseStandingInstructions StandingInstructions { get; }

        public ICaseViewStandingInstructions Subject { get; }

        public CaseViewStandingInstructionFixture WithCaseStandingInstructions(CompositeInstruction[] instructions)
        {
            StandingInstructions.Retrieve(Arg.Any<int>()).ReturnsForAnyArgs(instructions);

            return this;
        }

        public CaseViewStandingInstructionFixture WithHomeCountrySiteControl(Country country)
        {
            SiteConfiguration.HomeCountry().Returns(country);
            return this;
        }

        public CaseViewStandingInstructionFixture WithUser(bool isExternal)
        {
            SecurityContext.User.Returns(new User("fee-earner", false));
            return this;
        }
    }

    public class FakeData
    {
        readonly InMemoryDbContext _db;

        public FakeData(InMemoryDbContext db)
        {
            _db = db;

            Instructions = new Dictionary<int, Instruction>();

            InstructionTypes = new Dictionary<string, InstructionType>();

            NameTypes = new Dictionary<string, NameType>();
        }

        Dictionary<string, InstructionType> InstructionTypes { get; }

        public Dictionary<int, Instruction> Instructions { get; }

        Dictionary<string, NameType> NameTypes { get; }

        public FakeData WithCaseDetails(int caseId, int? officeNameNum = null, string propertyTypeId = null, string countryId = null)
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

        NameType BuildNameType(string nameTypeCode, bool isRestricted = false)
        {
            if (NameTypes.TryGetValue(nameTypeCode, out var nameType))
            {
                return nameType;
            }

            NameTypes.Add(nameTypeCode, new NameType {NameTypeCode = nameTypeCode, Name = Fixture.String(), IsNameRestricted = isRestricted ? 1 : 0}.In(_db));

            return NameTypes[nameTypeCode];
        }

        InstructionType BuildInstructionType(string insTypeCode, string nameTypeCode = null)
        {
            if (InstructionTypes.TryGetValue(insTypeCode, out var instructionType))
            {
                return instructionType;
            }

            var instrType = new InstructionType
            {
                Code = insTypeCode,
                NameType = string.IsNullOrEmpty(nameTypeCode) ? null : BuildNameType(nameTypeCode)
            }.In(_db);

            InstructionTypes.Add(insTypeCode, instrType);

            return InstructionTypes[insTypeCode];
        }

        void BuildInstruction(short instrId, string instrTypeCode)
        {
            if (Instructions.TryGetValue(instrId, out _))
            {
                return;
            }

            var instruction = new Instruction
            {
                Id = instrId,
                Description = Fixture.RandomString(10),
                InstructionTypeCode = instrTypeCode,
                InstructionType = BuildInstructionType(instrTypeCode)
            }.In(_db);

            Instructions.Add(instrId, instruction);
        }

        public FakeData WithAdjustments()
        {
            new DateAdjustment {Id = KnownAdjustment.Annual}.In(_db);
            new DateAdjustment {Id = KnownAdjustment.Fortnightly}.In(_db);
            new DateAdjustment {Id = KnownAdjustment.UserDate}.In(_db);
            return this;
        }

        public FakeData WithTableCodes()
        {
            new TableCode(1, (short) TableTypes.MonthsOfYear, "ab", "1").In(_db);
            new TableCode(2, (short) TableTypes.MonthsOfYear, "cd", "2").In(_db);
            new TableCode(3, (short) TableTypes.MonthsOfYear, "ef", "3").In(_db);
            new TableCode(4, (short) TableTypes.MonthsOfYear, "gh", "4").In(_db);
            new TableCode(5, (short) TableTypes.MonthsOfYear, "ij", "5").In(_db);
            new TableCode(6, (short) TableTypes.MonthsOfYear, "kl", "6").In(_db);

            new TableCode(7, (short) TableTypes.DaysOfWeek, "abc", "2").In(_db);
            new TableCode(8, (short) TableTypes.DaysOfWeek, "ijk", "3").In(_db);
            new TableCode(9, (short) TableTypes.DaysOfWeek, "xyz", "5").In(_db);

            new TableCode(10, (short) TableTypes.PeriodType, "day", "d").In(_db);
            new TableCode(11, (short) TableTypes.PeriodType, "month", "m").In(_db);
            new TableCode(12, (short) TableTypes.PeriodType, "week", "w").In(_db);
            return this;
        }

        public FakeData WithName(int nameId)
        {
            new Name(nameId).In(_db);

            return this;
        }

        public FakeData WithNameType(string nameTypeCode, bool isRestricted = false)
        {
            BuildNameType(nameTypeCode, isRestricted);

            return this;
        }

        public FakeData WithInstructionType(string insTypeCode, string nameTypeCode)
        {
            BuildInstructionType(insTypeCode, nameTypeCode);
            return this;
        }

        public FakeData WithInstruction(short instrId, string instrTypeCode)
        {
            BuildInstruction(instrId, instrTypeCode);

            return this;
        }

        public FakeData WithNameInstruction(int nameNo, int sequence, short? instrId = null, int? caseId = null, string standingInstructionText = null, DateTime? adjustmentToDate = null,
                                            short? period1Amt = null, string period1Type = null, short? period2Amt = null, string period2Type = null, short? period3Amt = null, string period3Type = null,
                                            string adjustment = null, byte? adjustmentDay = null, byte? adjustStartMonth = null, byte? adjustDayOfWeek = null)
        {
            new NameInstruction
            {
                Id = nameNo,
                InstructionId = instrId,
                Sequence = sequence,
                CaseId = caseId,
                Period1Amt = period1Amt,
                Period1Type = period1Type,
                Period2Amt = period2Amt,
                Period2Type = period2Type,
                Period3Amt = period3Amt,
                Period3Type = period3Type,
                Adjustment = adjustment,
                StandingInstructionText = standingInstructionText,
                AdjustDay = adjustmentDay,
                AdjustDayOfWeek = adjustDayOfWeek,
                AdjustStartMonth = adjustStartMonth,
                AdjustToDate = adjustmentToDate
            }.In(_db);
            return this;
        }
    }
}