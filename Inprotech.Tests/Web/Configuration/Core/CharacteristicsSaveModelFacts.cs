using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;
using Characteristic = InprotechKaizen.Model.StandingInstructions.Characteristic;
using InstructionType = Inprotech.Web.Picklists.InstructionType;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class CharacteristicsSaveModelFacts : FactBase
    {
        public class CharacteristicsSaveModelFixture : IFixture<ICharacteristicsSaveModel>
        {
            readonly InMemoryDbContext _db;

            public CharacteristicsSaveModelFixture(InMemoryDbContext db)
            {
                _db = db;
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

                Subject = new CharacteristicsSaveModel(db, LastInternalCodeGenerator);

                LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.InstructionLabel).Returns(999);
            }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; }

            public ICharacteristicsSaveModel Subject { get; }

            public CharacteristicsSaveModelFixture WithInstructionType(short id = 1, string code = "A", string description = "existing type")
            {
                new InstructionType {Key = id, Code = code, Value = description}.In(_db);

                return this;
            }

            public CharacteristicsSaveModelFixture WithCharacteristics(short id = 1, string description = "existing char", string instructionTypeCode = "A")
            {
                new Characteristic {Id = id, Description = description, InstructionTypeCode = instructionTypeCode}.In(_db);

                return this;
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void AddsProvidedCharacteristics()
            {
                var delta = new Delta<DeltaCharacteristic>();
                delta.Added.Add(new DeltaCharacteristic {Id = "temp1", Description = "a"});

                var f = new CharacteristicsSaveModelFixture(Db)
                    .WithInstructionType();
                f.Subject.Save("A", delta);

                Assert.Single(Db.Set<Characteristic>().Where(_ => _.InstructionTypeCode == "A"));
                Assert.Equal("999", delta.Added.Single(_ => _.Id == "temp1").CorrelationId);
            }

            [Fact]
            public void DeletesProvidedCharacteristic()
            {
                var delta = new Delta<DeltaCharacteristic>();
                delta.Deleted.Add(new DeltaCharacteristic {Id = "1", Description = "New Desc"});

                var f = new CharacteristicsSaveModelFixture(Db)
                        .WithInstructionType()
                        .WithCharacteristics();
                f.Subject.Save("A", delta);

                var count = Db.Set<Characteristic>().Count(_ => _.InstructionTypeCode == "A");
                Assert.Equal(0, count);
            }

            [Fact]
            public void UpdatesProvidedCharacteristic()
            {
                var delta = new Delta<DeltaCharacteristic>();
                delta.Updated.Add(new DeltaCharacteristic {Id = "1", Description = "New Desc"});

                var f = new CharacteristicsSaveModelFixture(Db)
                        .WithInstructionType()
                        .WithCharacteristics();
                f.Subject.Save("A", delta);

                Assert.Single(Db.Set<Characteristic>().Where(_ => _.InstructionTypeCode == "A"));

                var characteristic = Db.Set<Characteristic>().First();
                Assert.Equal("New Desc", characteristic.Description);
            }
        }
    }
}