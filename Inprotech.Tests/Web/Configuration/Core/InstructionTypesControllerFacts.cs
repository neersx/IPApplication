using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.StandingInstructions;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class InstructionTypesControllerFacts : FactBase
    {
        public class Data
        {
            readonly InMemoryDbContext _db;

            public Data(InMemoryDbContext db)
            {
                _db = db;
            }

            public NameType NameType(string type, string description)
            {
                return new NameTypeBuilder
                       {
                           NameTypeCode = type,
                           Name = description
                       }
                       .Build()
                       .In(_db);
            }
        }

        public class InstructionTypesControllerFixture : IFixture<InstructionTypesController>
        {
            readonly InMemoryDbContext _db;

            public InstructionTypesControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                InstructionTypeSaveModel = Substitute.For<IInstructionTypeSaveModel>();

                Subject = new InstructionTypesController(db, InstructionTypeSaveModel);
            }

            public IInstructionTypeSaveModel InstructionTypeSaveModel { get; set; }

            public InstructionTypesController Subject { get; }

            public InstructionType GetInstructionType(string type)
            {
                return _db.Set<InstructionType>().Single(_ => _.Code == type);
            }

            public Instruction GetInstruction(string type, string instructionDesc)
            {
                return _db.Set<Instruction>()
                          .Single(_ => _.InstructionTypeCode == type && _.Description == instructionDesc);
            }

            public Characteristic GetCharacteristics(string type, string description)
            {
                return _db.Set<Characteristic>()
                          .Single(_ => _.InstructionTypeCode == type && _.Description == description);
            }

            public InstructionTypesControllerFixture WithInstructionType(string type, string description,
                                                                         NameType recordedAgainst = null, NameType restrictedTo = null, int id = 1)
            {
                new InstructionType
                {
                    Description = description,
                    Code = type,
                    NameType = recordedAgainst,
                    RestrictedByType = restrictedTo,
                    Instructions = new List<Instruction>(),
                    Characteristics = new List<Characteristic>()
                }.In(_db);
                return this;
            }

            public InstructionTypesControllerFixture WithInstruction(string type, string description)
            {
                GetInstructionType(type)
                    .Instructions.Add(new Instruction
                    {
                        InstructionTypeCode = type,
                        Description = description,
                        Characteristics = new List<SelectedCharacteristic>()
                    }.In(_db));

                return this;
            }

            public InstructionTypesControllerFixture WithBaseCharacteristics(string type, string description)
            {
                var count = (short) _db.Set<Characteristic>().Count();
                GetInstructionType(type)
                    .Characteristics.Add(new Characteristic
                    {
                        Id = ++count,
                        Description = description,
                        InstructionTypeCode = type
                    }.In(_db));

                return this;
            }

            public InstructionTypesControllerFixture WithCharacteristics(string type, string instruction,
                                                                         string description)
            {
                var characteristics = GetCharacteristics(type, description);

                GetInstruction(type, instruction)
                    .Characteristics.Add(new SelectedCharacteristic
                    {
                        CharacteristicId = characteristics.Id
                    }.In(_db));

                return this;
            }
        }

        public class InstructionTypesMethod : FactBase
        {
            public InstructionTypesMethod()
            {
                _instructor = new Data(Db).NameType(KnownNameTypes.Instructor, "instructor");
                _owner = new Data(Db).NameType(KnownNameTypes.Owner, "owner");
            }

            readonly NameType _instructor;
            readonly NameType _owner;

            [Fact]
            public void ReturnsAllInstructionsTypes()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaa", _instructor)
                        .WithInstructionType("b", "bbbb", _instructor)
                        .WithInstructionType("c", "cccc", _owner);

                var r = ((IEnumerable<dynamic>) f.Subject.InstructionTypes()).ToArray();

                Assert.Equal(3, r.Length);
            }

            [Fact]
            public void ReturnsDetails()
            {
                var f = new InstructionTypesControllerFixture(Db)
                    .WithInstructionType("a", "aaaa", _instructor, _owner);

                var r = ((IEnumerable<dynamic>) f.Subject.InstructionTypes()).ToArray();

                Assert.Equal(1, r.Single().Id);
                Assert.Equal("a", r.Single().Code);
            }
        }

        public class InstructionTypesDetailsMethod : FactBase
        {
            public InstructionTypesDetailsMethod()
            {
                _instructor = new Data(Db).NameType(KnownNameTypes.Instructor, "instructor");
                _owner = new Data(Db).NameType(KnownNameTypes.Owner, "owner");
            }

            readonly NameType _instructor;
            readonly NameType _owner;

            [Fact]
            public void ReturnsBlankArrays()
            {
                var f = new InstructionTypesControllerFixture(Db)
                    .WithInstructionType("a", "aaaaa", _instructor, _owner);

                var r = f.Subject.InstructionTypesDetails(1);

                Assert.Empty(r.Characteristics);
                Assert.Empty(r.Instructions);
            }

            [Fact]
            public void ReturnsRelatedCharacteristics()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaaa", _instructor, _owner)
                        .WithBaseCharacteristics("a", "char1")
                        .WithBaseCharacteristics("a", "char2")
                        .WithBaseCharacteristics("a", "char3");

                var r = f.Subject.InstructionTypesDetails(1);

                var characteristics = ((IEnumerable<dynamic>) r.Characteristics).ToArray();

                Assert.Equal(3, characteristics.Length);
                Assert.Empty(r.Instructions);
            }

            [Fact]
            public void ReturnsRelatedInstructions()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaaa", _instructor, _owner)
                        .WithInstruction("a", "ins1")
                        .WithInstruction("a", "ins2")
                        .WithInstruction("a", "ins3");

                var r = f.Subject.InstructionTypesDetails(1);
                var instructions = ((IEnumerable<dynamic>) r.Instructions).ToArray();

                Assert.Empty(r.Characteristics);
                Assert.Equal(3, instructions.Length);
            }

            [Fact]
            public void ReturnsSelectedCharacteristics()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaaa", _instructor, _owner)
                        .WithBaseCharacteristics("a", "char1")
                        .WithBaseCharacteristics("a", "char2")
                        .WithBaseCharacteristics("a", "char3")
                        .WithInstruction("a", "ins1")
                        .WithCharacteristics("a", "ins1", "char1")
                        .WithCharacteristics("a", "ins1", "char2");

                var r = f.Subject.InstructionTypesDetails(1);

                var characteristics = ((IEnumerable<dynamic>) r.Characteristics).ToArray();
                var instructions = ((IEnumerable<dynamic>) r.Instructions).ToArray();

                Assert.Equal(3, characteristics.Length);
                Assert.Single(instructions);

                var assignedCharacteristics = ((IEnumerable<dynamic>) instructions.First().Characteristics).ToArray();
                Assert.Equal(3, assignedCharacteristics.Length);
            }
        }

        public class InstructionTypesSaveMethod : FactBase
        {
            public InstructionTypesSaveMethod()
            {
                _instructor = new Data(Db).NameType(KnownNameTypes.Instructor, "instructor");
                _owner = new Data(Db).NameType(KnownNameTypes.Owner, "owner");
            }

            readonly NameType _instructor;
            readonly NameType _owner;

            [Fact]
            public void CallsSaveModelForInstructionType()
            {
                var f = new InstructionTypesControllerFixture(Db);

                const string input = "{'instrType': {id: 4, added: [] } }";

                f.Subject.Save(JObject.Parse(input));
                f.InstructionTypeSaveModel.Received(1).Save(Arg.Any<DeltaInstructionTypeDetails>(), out _);
            }

            [Fact]
            public void ReturnsDataWithNewlyAddedCharacteristics()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaaa", _instructor, _owner)
                        .WithBaseCharacteristics("a", "char1");

                const string input = "{'instrType': {id: 1, characteristics:{added: [{ id: 'temp1', description: 'a', correlationId: '1'}]}}}";

                f.InstructionTypeSaveModel.Save(Arg.Any<DeltaInstructionTypeDetails>(), out _).Returns(true);
                var resultRecieved = f.Subject.Save(JObject.Parse(input));

                f.InstructionTypeSaveModel.Received(1).Save(Arg.Any<DeltaInstructionTypeDetails>(), out _);
                Assert.Equal(resultRecieved.Result, "success");

                var characteristics = ((IEnumerable<dynamic>) resultRecieved.Data.characteristics).ToArray();
                Assert.Equal(characteristics.First().Id, 1);
                Assert.Equal(characteristics.First().CorrelationId, "temp1");
            }

            [Fact]
            public void ReturnsDataWithNewlyAddedInstruction()
            {
                var f = new InstructionTypesControllerFixture(Db)
                        .WithInstructionType("a", "aaaaa", _instructor, _owner)
                        .WithInstruction("a", "ins1");

                const string input = "{'instrType': {id: 1, instructions:{added: [{ id: 'temp1', description: 'a', correlationId: '2'}]}}}";

                f.InstructionTypeSaveModel.Save(Arg.Any<DeltaInstructionTypeDetails>(), out _).Returns(true);
                var resultRecieved = f.Subject.Save(JObject.Parse(input));

                f.InstructionTypeSaveModel.Received(1).Save(Arg.Any<DeltaInstructionTypeDetails>(), out _);
                Assert.Equal(resultRecieved.Result, "success");

                var instructions = ((IEnumerable<dynamic>) resultRecieved.Data.instructions).ToArray();
                Assert.Equal(instructions.First().Id, 2);
                Assert.Equal(instructions.First().CorrelationId, "temp1");
            }

            [Fact]
            public void ReturnsErrorIdSaveModelReturnsError()
            {
                var f = new InstructionTypesControllerFixture(Db);
                const string input = "{'instrType': {id: 4, added: [] } }";

                f.InstructionTypeSaveModel.Save(Arg.Any<DeltaInstructionTypeDetails>(), out var validationResult).Returns(false);
                var resultRecieved = f.Subject.Save(JObject.Parse(input));

                f.InstructionTypeSaveModel.Received(1).Save(Arg.Any<DeltaInstructionTypeDetails>(), out validationResult);
                Assert.Equal(resultRecieved, validationResult);
            }

            [Fact]
            public void ReturnsSuccessWithModifiedData()
            {
                var f = new InstructionTypesControllerFixture(Db)
                    .WithInstructionType("a", "aaaaa", _instructor, _owner);

                const string input = "{'instrType': {id: 1, added: [] } }";

                f.InstructionTypeSaveModel.Save(Arg.Any<DeltaInstructionTypeDetails>(), out _).Returns(true);
                var resultRecieved = f.Subject.Save(JObject.Parse(input));

                f.InstructionTypeSaveModel.Received(1).Save(Arg.Any<DeltaInstructionTypeDetails>(), out _);
                Assert.Equal(resultRecieved.Result, "success");
            }
        }
    }
}