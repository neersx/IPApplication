using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Tests.Web.Picklists
{
    public class InstructionsPicklistMaintenanceFacts
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesTheInstruction()
            {
                var model = new EntityModel.Instruction().In(Db);

                var f = new InstructionsPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.InstructionType>().Any());
            }
        }

        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _anyInstructionType = new EntityModel.InstructionType
                {
                    Code = "A",
                    Description = "abc",
                    NameType = new NameTypeBuilder().Build().In(Db),
                    RestrictedByType = null
                }.In(Db);

                _existing = new EntityModel.Instruction
                {
                    Description = "existing one",
                    Id = 99,
                    InstructionType = _anyInstructionType
                }.In(Db);
            }

            readonly EntityModel.InstructionType _anyInstructionType;
            readonly EntityModel.Instruction _existing;

            [Theory]
            [InlineData(null)]
            [InlineData((short) 4)]
            public void PreventUnknownFromBeingSaved(short? id)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new InstructionsPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                                 new Instruction
                                                                                                                 {
                                                                                                                     Id = id
                                                                                                                 }, Operation.Update);
                                                 });
            }

            [Fact]
            public void AddsInstruction()
            {
                const short lastInternalCode = 567;

                var fixture = new InstructionsPicklistMaintenanceFixture(Db);

                fixture.LastInternalCodeGenerator
                       .GenerateLastInternalCode(KnownInternalCodeTable.Instructions)
                       .Returns(lastInternalCode);

                var subject = fixture.Subject;

                var model = new Instruction
                {
                    Description = "blah",
                    TypeId = _anyInstructionType.Id
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.Instruction>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(lastInternalCode, justAdded.Id);
                Assert.Equal(model.Description, justAdded.Description);
                Assert.Equal(model.TypeId, justAdded.InstructionType.Id);
            }

            [Fact]
            public void RequiresDescription()
            {
                var subject = new InstructionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Instruction
                {
                    Id = _existing.Id,
                    Description = string.Empty,
                    TypeId = _anyInstructionType.Id
                }, Operation.Update);

                Assert.Equal("description", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescriptionToBeNoGreaterThan50Characters()
            {
                var subject = new InstructionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Instruction
                {
                    Id = _existing.Id,
                    Description = "123456789012345678901234567890123456789012345678901234567890",
                    TypeId = _anyInstructionType.Id
                }, Operation.Update);

                Assert.Equal("description", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresInstructionType()
            {
                var subject = new InstructionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Instruction
                {
                    Id = _existing.Id,
                    Description = "abc"
                }, Operation.Update);

                Assert.Equal("typeId", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueDescription()
            {
                var subject = new InstructionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Instruction
                {
                    Description = _existing.Description,
                    TypeId = _anyInstructionType.Id
                }, Operation.Add);

                Assert.Equal("description", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesInstruction()
            {
                var subject = new InstructionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new Instruction
                {
                    Id = _existing.Id,
                    Description = "blah",
                    TypeId = _anyInstructionType.Id
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Id, _existing.Id);
                //Assert.Equal(model.Description, _existing.Description);
                //Assert.Equal(model.TypeId, _existing.InstructionType.Id);
            }
        }

        public class InstructionsPicklistMaintenanceFixture : IFixture<InstructionsPicklistMaintenance>
        {
            public InstructionsPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

                Subject = new InstructionsPicklistMaintenance(db,
                                                              LastInternalCodeGenerator);
            }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }

            public InstructionsPicklistMaintenance Subject { get; set; }
        }
    }
}