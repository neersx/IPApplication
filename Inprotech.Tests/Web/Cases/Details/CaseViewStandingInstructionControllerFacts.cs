using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewStandingInstructionControllerFacts : FactBase
    {
        [Fact]
        public async Task ReturnsCanViewFlagCorrectly()
        {
            var instructions = new[]
            {
                new CaseViewStandingInstruction {NameNo = 1234, Description = "Done", InstructionTypeDesc = "DoWork", InstructionTypeCode = "A"},
                new CaseViewStandingInstruction {NameNo = 4567, Description = "NotDone", InstructionTypeDesc = "DootWork", InstructionTypeCode = "B"}
            };

            var f = new CaseViewStandingInstructionControllerFixture(Db)
                    .WithCaseStandingInstructions(instructions)
                    .WithUserFilterTypes(new[] {"A", "B"})
                    .WithNameAuthorization(new[] {1234})
                    .WithNames(new[] {1234, 4567});

            var result = (await f.Subject.GetStandingInstructions(10)).ToArray();
            Assert.Equal(2, result.Length);

            var instruction1 = result.Single(_ => _.NameNo == 1234);
            Assert.NotNull(instruction1.DefaultedFrom);
            Assert.True(instruction1.CanView);

            var instruction2 = result.Single(_ => _.NameNo == 4567);
            Assert.NotNull(instruction1.DefaultedFrom);
            Assert.False(instruction2.CanView);
        }

        [Fact]
        public async Task ReturnsCaseInstructions()
        {
            var instructions = new[]
            {
                new CaseViewStandingInstruction {NameNo = 1234, Description = "Done", InstructionTypeDesc = "DoWork", InstructionTypeCode = "A"}
            };

            var f = new CaseViewStandingInstructionControllerFixture(Db)
                    .WithNames(new[] {1234})
                    .WithUserFilterTypes(new[] {"A"})
                    .WithCaseStandingInstructions(instructions);

            var result = (await f.Subject.GetStandingInstructions(10)).ToArray();
            Assert.Equal(1, result.Length);
            Assert.Equal(instructions[0].InstructionTypeDesc, result[0].InstructionType);
            Assert.Equal(instructions[0].Description, result[0].Instruction);
            Assert.False(result[0].CanView);
            Assert.Equal(instructions[0].NameNo, result[0].NameNo);
        }

        [Fact]
        public async Task ReturnsDefaultedFromCorrectly()
        {
            var instructions = new[]
            {
                new CaseViewStandingInstruction {NameNo = 1234, Description = "Done", InstructionTypeDesc = "DoWork", InstructionTypeCode = "A"},
                new CaseViewStandingInstruction {NameNo = 4567, Description = "NotDone", InstructionTypeDesc = "DootWork", CaseId = 10, InstructionTypeCode = "B"}
            };

            var f = new CaseViewStandingInstructionControllerFixture(Db)
                    .WithUserFilterTypes(new[] {"A", "B"})
                    .WithCaseStandingInstructions(instructions)
                    .WithNames(new[] {1234, 4567});

            var result = (await f.Subject.GetStandingInstructions(10)).ToArray();
            Assert.Equal(2, result.Length);

            var instruction1 = result.Single(_ => _.NameNo == 1234);
            Assert.NotNull(instruction1.DefaultedFrom);

            var name = Db.Set<Name>().Single(_ => _.Id == 1234);

            Assert.Contains(name.LastName, instruction1.DefaultedFrom);
            Assert.Contains(name.FirstName, instruction1.DefaultedFrom);

            var instruction2 = result.Single(_ => _.NameNo == 4567);
            Assert.Null(instruction2.DefaultedFrom);
        }

        [Fact]
        public async Task ReturnsEmptyIfNoInstructionsFound()
        {
            var f = new CaseViewStandingInstructionControllerFixture(Db)
                .WithCaseStandingInstructions(new CaseViewStandingInstruction[] { });

            var result = await f.Subject.GetStandingInstructions(10);
            Assert.Empty(result);
        }

        [Fact]
        public async Task ReturnsOnlyViewableInstructionTypes()
        {
            var instructions = new[]
            {
                new CaseViewStandingInstruction {NameNo = 1234, Description = "Done", InstructionTypeDesc = "DoWork", InstructionTypeCode = "A"},
                new CaseViewStandingInstruction {NameNo = 4567, Description = "NotDone", InstructionTypeDesc = "DootWork", InstructionTypeCode = "B"}
            };

            var f = new CaseViewStandingInstructionControllerFixture(Db)
                    .WithUserFilterTypes(new[] {"A"})
                    .WithCaseStandingInstructions(instructions, new[] {"A"})
                    .WithNameAuthorization(new[] {1234})
                    .WithNames(new[] {1234, 4567});

            var result = (await f.Subject.GetStandingInstructions(10)).ToArray();
            Assert.Equal(1, result.Length);

            Assert.Equal("DoWork", result[0].InstructionType);
        }
    }

    public class CaseViewStandingInstructionControllerFixture : IFixture<CaseViewStandingInstructionController>
    {
        readonly InMemoryDbContext _db;

        public CaseViewStandingInstructionControllerFixture(InMemoryDbContext db)
        {
            _db = db;

            CaseViewStandingInstructions = Substitute.For<ICaseViewStandingInstructions>();
            NameAuthorization = Substitute.For<INameAuthorization>();
            UserFilteredTypes = Substitute.For<IUserFilteredTypes>();
            FormattedNameAddressTelecom = Substitute.For<IFormattedNameAddressTelecom>();
            FormattedNameAddressTelecom.GetFormatted(Arg.Any<int[]>(), NameStyles.FirstNameThenFamilyName)
                                       .Returns(x =>
                                       {
                                           var nameIds = ((int[]) x[0]).Distinct();
                                           return (from n in db.Set<Name>()
                                                   where nameIds.Contains(n.Id)
                                                   select new NameFormatted
                                                   {
                                                       NameId = n.Id,
                                                       Name = n.FirstName + " " + n.LastName,
                                                       NameCode = n.NameCode,
                                                       Nationality = "nationality" + Fixture.String(),
                                                       MainPostalAddressId = n.PostalAddressId,
                                                       MainStreetAddressId = n.StreetAddressId,
                                                       MainPhone = n.MainPhone().FormattedOrNull(),
                                                       MainEmail = n.MainEmail().FormattedOrNull()
                                                   })
                                               .ToDictionary(k => k.NameId, v => v);
                                       });

            Subject = new CaseViewStandingInstructionController(CaseViewStandingInstructions, FormattedNameAddressTelecom, NameAuthorization, UserFilteredTypes);
        }

        public IFormattedNameAddressTelecom FormattedNameAddressTelecom { get; set; }

        public ICaseViewStandingInstructions CaseViewStandingInstructions { get; set; }

        public INameAuthorization NameAuthorization { get; set; }

        public IUserFilteredTypes UserFilteredTypes { get; set; }

        public CaseViewStandingInstructionController Subject { get; }

        public CaseViewStandingInstructionControllerFixture WithCaseStandingInstructions(CaseViewStandingInstruction[] instructions, string[] instructionTypes = null)
        {
            if (instructionTypes != null)
            {
                var filtered = instructions.Where(_ => instructionTypes.Contains(_.InstructionTypeCode)).ToArray();

                CaseViewStandingInstructions.GetCaseStandingInstructions(Arg.Any<int>(), Arg.Any<string[]>())
                                            .Returns(filtered);
            }
            else
            {
                CaseViewStandingInstructions.GetCaseStandingInstructions(Arg.Any<int>(), Arg.Any<string[]>())
                                            .ReturnsForAnyArgs(instructions);
            }

            return this;
        }

        public CaseViewStandingInstructionControllerFixture WithNameAuthorization(int[] nameIds)
        {
            NameAuthorization.AccessibleNames().ReturnsForAnyArgs(nameIds);

            return this;
        }

        public CaseViewStandingInstructionControllerFixture WithUserFilterTypes(string[] instructionTypeCodes)
        {
            var instructionTypes = instructionTypeCodes.Select(instrTypeCode => new InstructionType {Code = instrTypeCode}).ToList();

            UserFilteredTypes.InstructionTypes()
                             .ReturnsForAnyArgs(instructionTypeCodes.Length > 0 
                                                    ? instructionTypes.AsQueryable() 
                                                    : new InstructionType[] { }.AsQueryable());
            return this;
        }

        public CaseViewStandingInstructionControllerFixture WithNames(int[] nameIds)
        {
            (nameIds ?? new int[0])
                .ToList()
                .ForEach(n => new Name
                {
                    FirstName = Fixture.String(),
                    LastName = Fixture.String()
                }.In(_db).WithKnownId(n));

            return this;
        }
    }
}