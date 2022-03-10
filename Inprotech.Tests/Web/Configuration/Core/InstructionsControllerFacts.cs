using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class InstructionsControllerFacts : FactBase
    {
        public class InstructionsControllerFixture : IFixture<InstructionsController>
        {
            readonly InMemoryDbContext _db;

            public InstructionsControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new InstructionsController(db, preferredCultureResolver);
            }

            public InstructionsController Subject { get; }

            public InstructionsControllerFixture WithInstruction(InstructionType instructionType, short id, string description)
            {
                instructionType.Instructions.Add(new Instruction
                {
                    Description = description,
                    Id = id,
                    InstructionType = instructionType,
                    InstructionTypeCode = instructionType.Code
                }.In(_db));

                return this;
            }
        }

        public class InstructionsMethod : FactBase
        {
            public InstructionsMethod()
            {
                _exam = new InstructionType
                {
                    Id = 1,
                    Code = Fixture.String(),
                    Description = "exam",
                    Instructions = new List<Instruction>()
                }.In(Db);

                _renewal = new InstructionType
                {
                    Id = 2,
                    Code = Fixture.String(),
                    Description = "renewal",
                    Instructions = new List<Instruction>()
                }.In(Db);
            }

            readonly InstructionType _exam;
            readonly InstructionType _renewal;

            [Fact]
            public void ReturnsDetails()
            {
                var f = new InstructionsControllerFixture(Db)
                    .WithInstruction(_exam, 1, "mars");

                var r = ((IEnumerable<dynamic>) f.Subject.Instructions(_exam.Id)).Single();

                Assert.Equal(1, r.Id);
                Assert.Equal(_exam.Id, r.TypeId);
                Assert.Equal("mars", r.Description);
            }

            [Fact]
            public void ReturnsInstructionsByType()
            {
                var f = new InstructionsControllerFixture(Db)
                        .WithInstruction(_exam, 1, "mars")
                        .WithInstruction(_exam, 2, "pluto")
                        .WithInstruction(_exam, 3, "jupiter");

                var r = ((IEnumerable<dynamic>) f.Subject.Instructions(_exam.Id)).ToArray();

                Assert.Equal(3, r.Length);
            }

            [Fact]
            public void ShouldNotReturnInstructionsFromOtherType()
            {
                var f = new InstructionsControllerFixture(Db)
                        .WithInstruction(_exam, 1, "mars")
                        .WithInstruction(_renewal, 2, "pluto")
                        .WithInstruction(_exam, 3, "jupiter");

                var r = ((IEnumerable<dynamic>) f.Subject.Instructions(_exam.Id)).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal("mars", r.First().Description);
                Assert.Equal("jupiter", r.Last().Description);
            }
        }
    }
}