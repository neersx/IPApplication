using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.StandingInstructions;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class InstructionTypeDetailsValidatorFacts : FactBase
    {
        public class InstructionTypeDetailsValidatorFixture : IFixture<IInstructionTypeDetailsValidator>
        {
            public InstructionTypeDetailsValidatorFixture(InMemoryDbContext db)
            {
                Subject = new InstructionTypeDetailsValidator(db);
            }

            public IInstructionTypeDetailsValidator Subject { get; }
        }

        public class InstructionTypeValidateMethod : FactBase
        {
            [Fact]
            public void ReturnErrorIdTypeIdIsNull()
            {
                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate(null, new DeltaInstructionTypeDetails(), out var validationResult);

                Assert.False(result);
                Assert.Equal(Resources.InstructionTypeNotFound, validationResult.Message);
            }

            [Fact]
            public void ReturnTrueIfTypeValid()
            {
                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate("A", new DeltaInstructionTypeDetails(), out var validationResult);
                Assert.True(result);
                Assert.Null(validationResult);
            }
        }

        public class CharacteristicsValidateMethod : FactBase
        {
            [Fact]
            public void ReturnFalseIfAddedCharacteristicNotUnique()
            {
                new Characteristic {Id = 1, Description = "A", InstructionTypeCode = "A"}.In(Db);
                var delta = new DeltaInstructionTypeDetails {Id = 1};
                delta.Characteristics.Added.Add(new DeltaCharacteristic {Id = "temp1", Description = "A"});

                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate("A", delta, out var validationResult);
                Assert.False(result);

                Assert.Equal(Resources.CharacteristicsErrorTitle, validationResult.Message);
                Assert.Equal("temp1", validationResult.Errors.First().Id);
            }

            [Fact]
            public void ReturnFalseIfDeletedCharacteristicInUse()
            {
                new Characteristic {Id = 1, Description = "A", InstructionTypeCode = "A"}.In(Db).ChargeRates = new[] {new ChargeRates {ChargeTypeNo = 1, InstructionType = "A"}.In(Db)}.In(Db);
                var delta = new DeltaInstructionTypeDetails {Id = 1};
                delta.Characteristics.Deleted.Add(new DeltaCharacteristic {Id = "1", Description = "A"});

                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate("A", delta, out var validationResult);
                Assert.False(result);

                Assert.Equal(Resources.InstructionTypeCharacteristicsInUse, validationResult.Message);
                Assert.Equal("1", validationResult.Errors.First().Id);
            }

            [Fact]
            public void ReturnFalseIfUpdatedCharacteristicNotUnique()
            {
                new Characteristic {Id = 1, Description = "A", InstructionTypeCode = "A"}.In(Db);
                var delta = new DeltaInstructionTypeDetails {Id = 1};
                delta.Characteristics.Updated.Add(new DeltaCharacteristic {Id = "4", Description = "A"});

                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate("A", delta, out var validationResult);
                Assert.False(result);

                Assert.Equal(Resources.CharacteristicsErrorTitle, validationResult.Message);
                Assert.Equal("4", validationResult.Errors.First().Id);
            }
        }

        public class InstructionsValidateMethod : FactBase
        {
            [Fact]
            public void ReturnFalseIfAddedInstructionNotUnique()
            {
                new Instruction {Id = 1, Description = "A", InstructionTypeCode = "A"}.In(Db);
                var delta = new DeltaInstructionTypeDetails {Id = 1};
                delta.Instructions.Added.Add(new DeltaInstruction {Id = "temp1", Description = "A"});

                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate("A", delta, out var validationResult);
                Assert.False(result);

                Assert.Equal(Resources.InstructionsErrorTitle, validationResult.Message);
                Assert.Equal("temp1", validationResult.Errors.First().Id);
            }

            [Fact]
            public void ReturnFalseIfDeletedInstructionInUse()
            {
                new Instruction
                {
                    Id = 1,
                    Description = "A",
                    InstructionTypeCode = "A"
                }.In(Db);

                var instruction2 = new Instruction
                {
                    Id = 2,
                    Description = "B",
                    InstructionTypeCode = "A"
                }.In(Db);
                instruction2.NameInstructions = new[] {new NameInstruction {InstructionId = 2}.In(Db)}.In(Db);

                var instruction3 = new Instruction
                {
                    Id = 3,
                    Description = "C",
                    InstructionTypeCode = "A"
                }.In(Db);

                instruction3.NameInstructions = new[] {new NameInstruction {InstructionId = 3}.In(Db)}.In(Db);
                instruction3.CaseInstructions = new[] {new CaseInstruction {InstructionType = "A", InstructionId = 3}.In(Db)}.In(Db);

                var delta = new DeltaInstructionTypeDetails
                {
                    Id = 1,
                    Instructions =
                    {
                        Deleted = new List<DeltaInstruction>
                        {
                            new DeltaInstruction {Id = "1"},
                            new DeltaInstruction {Id = "2"},
                            new DeltaInstruction {Id = "3"}
                        }
                    }
                };

                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate("A", delta, out var validationResult);
                Assert.False(result);

                Assert.Equal(validationResult.Message, Resources.InstructionTypeInstructionsInUse);
                Assert.Equal(2, validationResult.Errors.Count());

                var errorsInOrder = validationResult.Errors.OrderBy(_ => _.Id).ToArray();

                Assert.Equal(instruction2.Id.ToString(), errorsInOrder[0].Id);
                Assert.Equal(instruction3.Id.ToString(), errorsInOrder[1].Id);
            }

            [Fact]
            public void ReturnFalseIfUpdatedInstructionNotUnique()
            {
                new Instruction {Id = 1, Description = "A", InstructionTypeCode = "A"}.In(Db);
                var delta = new DeltaInstructionTypeDetails {Id = 1};
                delta.Instructions.Updated.Add(new DeltaInstruction {Id = "4", Description = "A"});

                var f = new InstructionTypeDetailsValidatorFixture(Db);

                var result = f.Subject.Validate("A", delta, out var validationResult);
                Assert.False(result);

                Assert.Equal(Resources.InstructionsErrorTitle, validationResult.Message);
                Assert.Equal("4", validationResult.Errors.First().Id);
            }
        }
    }
}