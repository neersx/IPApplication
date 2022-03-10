using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;
using InstructionType = Inprotech.Web.Picklists.InstructionType;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class InstructionsSaveModelFacts : FactBase
    {
        public class InstructionsSaveModelFixture : IFixture<IInstructionsSaveModel>
        {
            readonly InMemoryDbContext _db;

            public InstructionsSaveModelFixture(InMemoryDbContext db)
            {
                _db = db;

                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

                Subject = new InstructionsSaveModel(db, LastInternalCodeGenerator);

                LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Instructions).Returns(999);
            }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; }

            public IInstructionsSaveModel Subject { get; }

            public InstructionsSaveModelFixture WithInstructionType(short id = 1, string code = "A", string description = "existing type")
            {
                new InstructionType {Key = id, Code = code, Value = description}.In(_db);

                return this;
            }

            public InstructionsSaveModelFixture WithCharacteristic(short id = 1, string description = "existing char", string instructionTypeCode = "A")
            {
                new Characteristic {Id = id, Description = description, InstructionTypeCode = instructionTypeCode}.In(_db);

                return this;
            }

            public InstructionsSaveModelFixture WithInstruction(short id = 1, string description = "existing instr", string instructionTypeCode = "A", SelectedCharacteristic[] selectedCharacteristics = null)
            {
                var instruction = new Instruction {Id = id, Description = description, InstructionTypeCode = instructionTypeCode}.In(_db);
                if (selectedCharacteristics != null)
                {
                    instruction.Characteristics = selectedCharacteristics.In(_db);
                }

                return this;
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void AddCorrespondingAssignedCharacteristics()
            {
                var delta = new Delta<DeltaInstruction>();
                delta.Added.Add(new DeltaInstruction {Id = "temp1", Description = "a", Characteristics = new[] {new DeltaCharacteristic {Id = "1", Selected = true}}});

                var f = new InstructionsSaveModelFixture(Db)
                        .WithCharacteristic()
                        .WithInstructionType();
                f.Subject.Save("A", delta);

                var countAssigned = Db.Set<Instruction>().First().Characteristics.Count;
                Assert.Equal(1, countAssigned);
            }

            [Fact]
            public void AddsProvidedInstruction()
            {
                var delta = new Delta<DeltaInstruction>();
                delta.Added.Add(new DeltaInstruction {Id = "temp1", Description = "a"});

                var f = new InstructionsSaveModelFixture(Db)
                    .WithInstructionType();
                f.Subject.Save("A", delta);

                Assert.Single(Db.Set<Instruction>().Where(_ => _.InstructionTypeCode == "A"));
                Assert.Equal("999", delta.Added.Single(_ => _.Id == "temp1").CorrelationId);
            }

            [Fact]
            public void DeletesCorrespondingAssignedCharacteristics()
            {
                var delta = new Delta<DeltaInstruction>();
                delta.Deleted.Add(new DeltaInstruction {Id = "1", Description = "New Desc"});

                var f = new InstructionsSaveModelFixture(Db)
                        .WithInstructionType()
                        .WithCharacteristic()
                        .WithInstruction(1, "existing", "A", new[] {new SelectedCharacteristic {InstructionId = 1, CharacteristicId = 1}});
                f.Subject.Save("A", delta);

                var count = Db.Set<Instruction>().Count(_ => _.InstructionTypeCode == "A");
                Assert.Equal(0, count);

                var countAssigned = Db.Set<SelectedCharacteristic>().Count();
                Assert.Equal(0, countAssigned);
            }

            [Fact]
            public void DeletesProvidedInstruction()
            {
                var delta = new Delta<DeltaInstruction>();
                delta.Deleted.Add(new DeltaInstruction {Id = "1", Description = "New Desc"});

                var f = new InstructionsSaveModelFixture(Db)
                        .WithInstructionType()
                        .WithInstruction();
                f.Subject.Save("A", delta);

                var count = Db.Set<Instruction>().Count(_ => _.InstructionTypeCode == "A");
                Assert.Equal(0, count);
            }

            [Fact]
            public void SelectCorrespondingAssignedCharacteristics()
            {
                var delta = new Delta<DeltaInstruction>();
                delta.Updated.Add(new DeltaInstruction {Id = "1", Description = "new desc", Characteristics = new[] {new DeltaCharacteristic {Id = "1", Selected = true}}});

                var f = new InstructionsSaveModelFixture(Db)
                        .WithInstructionType()
                        .WithCharacteristic()
                        .WithInstruction();
                f.Subject.Save("A", delta);

                var countAssigned = Db.Set<SelectedCharacteristic>().Count();
                Assert.Equal(1, countAssigned);
            }

            [Fact]
            public void UnselectCorrespondingAssignedCharacteristics()
            {
                var delta = new Delta<DeltaInstruction>();
                delta.Updated.Add(new DeltaInstruction {Id = "1", Description = "new desc", Characteristics = new[] {new DeltaCharacteristic {Id = "1", Selected = false}}});

                var f = new InstructionsSaveModelFixture(Db)
                        .WithInstructionType()
                        .WithCharacteristic()
                        .WithInstruction(1, "existing", "A", new[] {new SelectedCharacteristic {InstructionId = 1, CharacteristicId = 1}});
                f.Subject.Save("A", delta);

                var countAssigned = Db.Set<SelectedCharacteristic>().Count();
                Assert.Equal(0, countAssigned);
            }

            [Fact]
            public void UpdatesProvidedInstruction()
            {
                var delta = new Delta<DeltaInstruction>();
                delta.Updated.Add(new DeltaInstruction {Id = "1", Description = "New Desc"});

                var f = new InstructionsSaveModelFixture(Db)
                        .WithInstructionType()
                        .WithInstruction();
                f.Subject.Save("A", delta);

                Assert.Single(Db.Set<Instruction>().Where(_ => _.InstructionTypeCode == "A"));

                var instruction = Db.Set<Instruction>().First();
                Assert.Equal("New Desc", instruction.Description);
            }
        }
    }
}