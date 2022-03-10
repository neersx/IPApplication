using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class InstructionTypeSaveModelFacts : FactBase
    {
        public class InstructionTypeSaveModelFixture : IFixture<InstructionTypeSaveModel>
        {
            readonly InMemoryDbContext _db;

            public InstructionTypeSaveModelFixture(InMemoryDbContext db)
            {
                _db = db;

                InstructionTypeDetailsValidator = Substitute.For<IInstructionTypeDetailsValidator>();
                InstructionsSaveModel = Substitute.For<IInstructionsSaveModel>();
                CharacteristicsSaveModel = Substitute.For<ICharacteristicsSaveModel>();

                Subject = new InstructionTypeSaveModel(_db, InstructionTypeDetailsValidator, CharacteristicsSaveModel, InstructionsSaveModel);
            }

            public IInstructionTypeDetailsValidator InstructionTypeDetailsValidator { get; set; }
            public IInstructionsSaveModel InstructionsSaveModel { get; set; }
            public ICharacteristicsSaveModel CharacteristicsSaveModel { get; set; }

            public InstructionTypeSaveModel Subject { get; }

            public InstructionTypeSaveModelFixture WithInstructionType(int id, string code, string description = "Some Description")
            {
                new InstructionType
                {
                    Id = id,
                    Code = code,
                    Description = description
                }.In(_db);
                return this;
            }

            public InstructionTypeSaveModelFixture WithValidationResponse(bool valid)
            {
                InstructionTypeDetailsValidator.Validate(string.Empty, null, out _).ReturnsForAnyArgs(valid);

                return this;
            }

            public InstructionTypeSaveModelFixture WithExceptionWhileCharacteristicsSave(string error)
            {
                CharacteristicsSaveModel.WhenForAnyArgs(c => c.Save(string.Empty, null)).Do(c => RaiseException(error));
                return this;
            }

            public InstructionTypeSaveModelFixture WithExceptionWhileInstructionsSave(string error)
            {
                InstructionsSaveModel.WhenForAnyArgs(c => c.Save(string.Empty, null)).Do(c => RaiseException(error));
                return this;
            }

            static void RaiseException(string message)
            {
                throw new Exception(message);
            }
        }

        static DeltaInstructionTypeDetails GetDelta(int typeId = 1)
        {
            return new DeltaInstructionTypeDetails {Id = typeId};
        }

        [Fact]
        public void RaisesExceptionIfErrorWhileSavingCharacateristics()
        {
            const string error = "Error while saving characteristics";
            var delta = GetDelta();
            var f = new InstructionTypeSaveModelFixture(Db)
                    .WithInstructionType(1, "A")
                    .WithValidationResponse(true)
                    .WithExceptionWhileCharacteristicsSave(error);
            var ex = Assert.Throws<Exception>(() => f.Subject.Save(delta, out _));
            Assert.Equal(ex.Message, error);
        }

        [Fact]
        public void SetIdsForAddedCharacteristics()
        {
            var delta = GetDelta();
            delta.Characteristics.Added.Add(new DeltaCharacteristic {Id = "temp1", CorrelationId = "1"});
            delta.Instructions.Added.Add(new DeltaInstruction {Id = "1"});
            delta.Instructions.Added.First().Characteristics.Add(new DeltaCharacteristic {Id = "temp1"});
            delta.Instructions.Updated.Add(new DeltaInstruction {Id = "1"});
            delta.Instructions.Updated.First().Characteristics.Add(new DeltaCharacteristic {Id = "temp1"});

            var f = new InstructionTypeSaveModelFixture(Db)
                    .WithInstructionType(1, "A")
                    .WithValidationResponse(true);

            f.Subject.Save(delta, out _);

            var assignedCharForAddedInstr = delta.Instructions.Added.First().Characteristics.First();
            Assert.Equal("1", assignedCharForAddedInstr.Id);

            var assignedCharForUpdatedInstr = delta.Instructions.Added.First().Characteristics.First();
            Assert.Equal("1", assignedCharForUpdatedInstr.Id);
        }

        [Fact]
        public void ShouldCallSaveMethodsSequencially()
        {
            var delta = GetDelta();
            var f = new InstructionTypeSaveModelFixture(Db)
                    .WithValidationResponse(true)
                    .WithInstructionType(1, "A");

            var result = f.Subject.Save(delta, out _);

            f.CharacteristicsSaveModel.Received(1).Save("A", delta.Characteristics);
            f.InstructionsSaveModel.Received(1).Save("A", delta.Instructions);

            Assert.True(result);
        }

        [Fact]
        public void ShouldNotCallSaveIfValidationFails()
        {
            var delta = GetDelta();
            var f = new InstructionTypeSaveModelFixture(Db)
                    .WithValidationResponse(false)
                    .WithInstructionType(1, "A");

            var result = f.Subject.Save(delta, out _);

            f.InstructionTypeDetailsValidator.Received(1)
             .Validate("A", Arg.Any<DeltaInstructionTypeDetails>(), out _);

            f.CharacteristicsSaveModel.Received(0).Save("A", delta.Characteristics);
            f.InstructionsSaveModel.Received(0).Save("A", delta.Instructions);

            Assert.False(result);
        }

        [Fact]
        public void WithExceptionWhileInstructionsSave()
        {
            const string error = "Error while saving instructions";
            var delta = GetDelta();
            var f = new InstructionTypeSaveModelFixture(Db)
                    .WithInstructionType(1, "A")
                    .WithValidationResponse(true)
                    .WithExceptionWhileCharacteristicsSave(error);

            var ex = Assert.Throws<Exception>(() => f.Subject.Save(delta, out _));
            Assert.Equal(ex.Message, error);
        }
    }
}