using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class CharacteristicsFacts
    {
        public class CharacteristicsFixture : IFixture<Inprotech.Web.Configuration.Core.Characteristics>
        {
            public CharacteristicsFixture(InMemoryDbContext db)
            {
                Subject = new Inprotech.Web.Configuration.Core.Characteristics(db, Substitute.For<IPreferredCultureResolver>());
            }

            public Inprotech.Web.Configuration.Core.Characteristics Subject { get; }
        }

        public class ForTypeMethod : FactBase
        {
            public ForTypeMethod()
            {
                _instructionType = new InstructionType
                {
                    Code = "A"
                }.In(Db);
            }

            readonly InstructionType _instructionType;

            [Fact]
            public void ReturnsAvailableCharacteristics()
            {
                _instructionType.Characteristics = new[]
                {
                    new Characteristic
                    {
                        Id = 1,
                        Description = "abc",
                        InstructionTypeCode = _instructionType.Code
                    }.In(Db),
                    new Characteristic
                    {
                        Id = 2,
                        Description = "def",
                        InstructionTypeCode = _instructionType.Code
                    }.In(Db)
                };

                var f = new CharacteristicsFixture(Db);
                var r = ((IEnumerable<dynamic>) f.Subject.ForType(_instructionType.Id))
                    .ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(1, r.First().Id);
                Assert.Equal("abc", r.First().Description);
            }

            [Fact]
            public void ShouldNotReturnOtherCharacteristics()
            {
                var otherType = new InstructionType {Code = "B", Characteristics = new List<Characteristic>()}.In(Db);

                _instructionType.Characteristics = new[]
                {
                    new Characteristic
                    {
                        Id = 1,
                        Description = "abc",
                        InstructionTypeCode = _instructionType.Code
                    }.In(Db)
                };

                var subject = new CharacteristicsFixture(Db).Subject;
                var r = (IEnumerable<dynamic>) subject.ForType(otherType.Id);

                Assert.False(r.Any());
            }
        }

        public class ForInstructionMethod : FactBase
        {
            [Fact]
            public void ReturnsSelectedCharacteristics()
            {
                const short instructionCode = 1;

                new Characteristic
                {
                    Id = 2,
                    Description = "req"
                }.In(Db);

                new SelectedCharacteristic
                {
                    InstructionId = instructionCode,
                    CharacteristicId = 2,
                    InstructionFlag = 0
                }.In(Db);

                var s = new CharacteristicsFixture(Db).Subject;
                var r = ((IEnumerable<dynamic>) s.ForInstruction(instructionCode)).ToArray();

                Assert.Single(r);
                Assert.Equal(2, r.First().Id);
                Assert.Equal("req", r.First().Description);
            }

            [Fact]
            public void ShouldNotReturnOtherCharacteristics()
            {
                new SelectedCharacteristic
                {
                    InstructionId = 2,
                    CharacteristicId = 2,
                    InstructionFlag = 0
                }.In(Db);

                var s = new CharacteristicsFixture(Db).Subject;
                var r = ((IEnumerable<dynamic>) s.ForInstruction(1)).ToArray();

                Assert.False(r.Any());
            }
        }
    }
}