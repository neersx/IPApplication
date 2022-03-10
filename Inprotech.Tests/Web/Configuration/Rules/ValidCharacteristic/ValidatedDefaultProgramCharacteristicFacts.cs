using System;
using System.Globalization;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedDefaultProgramCharacteristicFacts : FactBase
    {
        public class GetDefaultProgramMethod : FactBase
        {
            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData(" ")]
            public async Task ReturnsEmptyValidatedCharacteristicWhenNoDefaultProgramName(string programId)
            {
                var f = new ValidatedDefaultProgramCharacteristicFixture(Db);
                f.ListCasePrograms.GetDefaultCaseProgram().Returns(programId);
                var result = f.Subject.GetDefaultProgram();

                Assert.Null(result);
            }
            
            [Fact]
            public async Task ReturnsEmptyValidatedCharacteristicWhenNoDefaultProgramMatchingName()
            {
                var programId = Fixture.String();
                var f = new ValidatedDefaultProgramCharacteristicFixture(Db);
                f.ListCasePrograms.GetDefaultCaseProgram().Returns(programId);
                var result = f.Subject.GetDefaultProgram();

                Assert.Null(result);
            }
            
            [Fact]
            public async Task ReturnsValidatedCharacteristicWithMatchingProgramNameIfMatchFound()
            {
                var programId = Fixture.String();
                var programName = Fixture.String();
                new Program(programId, programName).In(Db);
                var f = new ValidatedDefaultProgramCharacteristicFixture(Db);
                f.ListCasePrograms.GetDefaultCaseProgram().Returns(programId);
                var result = f.Subject.GetDefaultProgram();

                Assert.True(result.IsValid);
                Assert.Equal(programId, result.Code);
                Assert.Equal(programId, result.Key);
                Assert.Equal(programName, result.Value);
            }
        }

        public class ValidatedDefaultProgramCharacteristicFixture : IFixture<ValidatedProgramCharacteristic>
        {
            public ValidatedDefaultProgramCharacteristicFixture(IDbContext db)
            {
                ListCasePrograms = Substitute.For<IListPrograms>();
                Subject = new ValidatedProgramCharacteristic(ListCasePrograms, db);
            }
            public IListPrograms ListCasePrograms { get; set; }

            public ValidatedProgramCharacteristic Subject { get; set; }
        }
    }
}
