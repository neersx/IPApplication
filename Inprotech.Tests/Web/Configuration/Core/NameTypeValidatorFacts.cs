using System.Linq;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class NameTypeValidatorFacts : FactBase
    {
        public class NameTypeValidatorFixture : IFixture<NameTypeValidator>
        {
            public NameTypeValidatorFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Subject = new NameTypeValidator(DbContext);
            }

            public IDbContext DbContext { get; }
            public NameTypeValidator Subject { get; }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ShouldReturnErrorIfNameTypeCodeAlreadyExist()
            {
                var f = new NameTypeValidatorFixture(Db);
                new NameType(1, "E", "Test").In(Db);

                var saveDetails = new NameTypeSaveDetails {Id = 2, NameTypeCode = "E"};

                var r = f.Subject.Validate(saveDetails, Operation.Add).ToArray();
                Assert.NotEmpty(r);
                Assert.Equal("nameTypeCode", r.First().Field);
                Assert.Equal("field.errors.notunique", r.First().Message);
            }

            [Fact]
            public void ShouldThrowExceptionIfNameTypeCodeDoesnotExist()
            {
                var saveDetails = new NameTypeSaveDetails {Id = 1, NameTypeCode = "*"};
                Assert.Throws<HttpResponseException>(() =>
                {
                    var f = new NameTypeValidatorFixture(Db);
                    var _ = f.Subject.Validate(saveDetails, Operation.Update).ToArray();
                });
            }
        }
    }
}