using System;
using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Picklists.ResponseShaping;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Picklists.ResponseShaping;
using NSubstitute;
using Xunit;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Web.Picklists
{
    public class InstructionsPicklistControllerFacts : FactBase
    {
        public class InstructionsMethod : FactBase
        {
            public InstructionsMethod()
            {
                _exam = new EntityModel.InstructionType
                {
                    Description = "exam",
                    Code = Fixture.String()
                }.In(Db);

                _renewal = new EntityModel.InstructionType
                {
                    Description = "renewal",
                    Code = Fixture.String()
                }.In(Db);
            }

            readonly EntityModel.InstructionType _exam;
            readonly EntityModel.InstructionType _renewal;

            [Fact]
            public void MarkExactMatchForDescription()
            {
                var f = new InstructionsControllerFixture(Db)
                        .WithInstruction(_exam, 1, "amars")
                        .WithInstruction(_exam, 2, "pluto")
                        .WithInstruction(_exam, 3, "jupiter");

                var r = f.Subject.Instructions(_exam.Id, null, "pluto");
                var i = r.Data.OfType<Instruction>().ToArray();

                Assert.Single(i);
                Assert.Equal("pluto", i.Single().Description);
            }

            [Fact]
            public void ReturnPagedResults()
            {
                for (var a = 0; a < 10; a++)
                {
                    new EntityModel.Instruction
                    {
                        Description = a.ToString(),
                        InstructionType = _exam,
                        InstructionTypeCode = _exam.Code
                    }.In(Db);
                }

                var r = new InstructionsControllerFixture(Db).Subject.Instructions(_exam.Id, new CommonQueryParameters {SortBy = "description", SortDir = "asc", Skip = 5, Take = 5});
                var i = r.Data.OfType<Instruction>().ToArray();

                Assert.Equal(5, i.Length);
                Assert.Equal("5", i.First().Description);
                Assert.Equal("9", i.Last().Description);
            }

            [Fact]
            public void ReturnsInstructionsByType()
            {
                var f = new InstructionsControllerFixture(Db)
                        .WithInstruction(_exam, 1, "mars")
                        .WithInstruction(_exam, 2, "pluto")
                        .WithInstruction(_exam, 3, "jupiter");

                var r = f.Subject.Instructions(_exam.Id);

                Assert.Equal(3, r.Data.Count());
            }

            [Fact]
            public void ReturnsInstructionsByTypeThatContains()
            {
                var f = new InstructionsControllerFixture(Db)
                        .WithInstruction(_exam, 1, "amars")
                        .WithInstruction(_exam, 2, "pluto")
                        .WithInstruction(_exam, 3, "jupiter");

                var r = f.Subject.Instructions(_exam.Id, null, "m");
                var i = r.Data.OfType<Instruction>().ToArray();

                Assert.Single(i);
                Assert.Equal("amars", i.Single().Description);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new InstructionsControllerFixture(Db).Subject.GetType();
                Assert.NotNull(subjectType.GetMethod("Instructions").GetCustomAttribute<PicklistPayloadAttribute>());
            }

            [Fact]
            public void ShouldNotReturnInstructionsFromOtherType()
            {
                var f = new InstructionsControllerFixture(Db)
                        .WithInstruction(_exam, 1, "mars")
                        .WithInstruction(_renewal, 2, "pluto")
                        .WithInstruction(_exam, 3, "jupiter");

                var r = f.Subject.Instructions(_exam.Id);
                var i = r.Data.OfType<Instruction>().ToArray();

                Assert.Equal(2, i.Length);
                Assert.Equal("mars", i.First().Description);
                Assert.Equal("jupiter", i.Last().Description);
            }

            [Fact]
            public void SortsByDescriptionDescending()
            {
                var f = new InstructionsControllerFixture(Db)
                        .WithInstruction(_exam, 1, "mars")
                        .WithInstruction(_exam, 2, "pluto")
                        .WithInstruction(_exam, 3, "jupiter");

                var r = f.Subject.Instructions(_exam.Id, new CommonQueryParameters {SortBy = "description", SortDir = "desc"});
                var i = r.Data.OfType<Instruction>().ToArray();

                Assert.Equal(3, i.Length);
                Assert.Equal("pluto", i.First().Description);
                Assert.Equal("jupiter", i.Last().Description);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new InstructionsControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.InstructionsPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new Instruction();

                Assert.Equal(r, s.Update(1, model));
                f.InstructionsPicklistMaintenance.Received(1).Save(model, Operation.Update);
            }
        }

        public class AddOrDuplicateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new InstructionsControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.InstructionsPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new Instruction();

                Assert.Equal(r, s.AddOrDuplicate(model));
                f.InstructionsPicklistMaintenance.Received(1).Save(model, Operation.Add);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new InstructionsControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.InstructionsPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.InstructionsPicklistMaintenance.Received(1).Delete(1);
            }
        }

        public class InstructionsControllerFixture : IFixture<InstructionsPicklistController>
        {
            readonly InMemoryDbContext _db;

            public InstructionsControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                var cultureResolver = Substitute.For<IPreferredCultureResolver>();

                InstructionsPicklistMaintenance = Substitute.For<IInstructionsPicklistMaintenance>();

                Subject = new InstructionsPicklistController(db, cultureResolver, InstructionsPicklistMaintenance);
            }

            public IInstructionsPicklistMaintenance InstructionsPicklistMaintenance { get; set; }

            public InstructionsPicklistController Subject { get; }

            public InstructionsControllerFixture WithInstruction(EntityModel.InstructionType instructionType, short id,
                                                                 string description)
            {
                new EntityModel.Instruction
                {
                    Description = description,
                    Id = id,
                    InstructionType = instructionType,
                    InstructionTypeCode = instructionType.Code
                }.In(_db);

                return this;
            }
        }
    }

    public class InstructionFacts
    {
        readonly Type _subject = typeof(Instruction);

        [Fact]
        public void DisplaysFollowingFields()
        {
            Assert.Equal(new[] {"Description", "TypeDescription"},
                         _subject.DisplayableFields());
        }

        [Fact]
        public void PicklistDescriptionIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Description")
                           .GetCustomAttribute<PicklistDescriptionAttribute>());
        }

        [Fact]
        public void PicklistKeyIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Id")
                           .GetCustomAttribute<PicklistKeyAttribute>());
        }
    }
}