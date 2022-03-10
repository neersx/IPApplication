using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class UserPasswordExpiryValidatorFacts : FactBase
    {
        public User ReturnsUserWithEmail()
        {
            var n = new NameBuilder(Db)
                    {
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "someone@cpaglobal.com"
                            }.Build()
                             .In(Db)
                    }
                    .Build()
                    .In(Db);

            return new UserBuilder(Db)
                       {
                           Name = n
                       }
                       .Build()
                       .In(Db);
        }

        [Theory]
        [InlineData(10, 1)]
        [InlineData(8, 1)]
        [InlineData(7, 1)]
        [InlineData(5, 1)]
        [InlineData(3, 0)]
        [InlineData(2, 0)]
        [InlineData(1, 1)]
        public async Task ReturnsUserWithExpiryDetails(int days, int count)
        {
            var user = ReturnsUserWithEmail();
            user.PasswordUpdatedDate = Fixture.Today().Subtract(TimeSpan.FromDays(days));
            
            var dataItem = new DocItem {Name = KnownEmailDocItems.PasswordExpiry, Sql = "Select ABC", EntryPointUsage = 1}.In(Db);
            var docItemResult = Fixture.String();
            var result = new DataSet();
            result.Tables.Add(new DataTable());
            result.Tables[0].Columns.Add("Result");
            var row = result.Tables[0].NewRow();
            row["Result"] = docItemResult;
            result.Tables[0].Rows.Add(row);

            var f = new UserPasswordExpiryValidatorFixture(Db);

            f.EmailValidator.IsValid(Arg.Any<string>()).Returns(true);
            f.DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(result);

            var r = await f.Subject.Resolve(8);
            var userPasswordExpiryDetails = r as UserPasswordExpiryDetails[] ?? r.ToArray();
            Assert.Equal(count, userPasswordExpiryDetails.Length);
            if (count != 1) return;
            Assert.Equal(user.Id , userPasswordExpiryDetails[0].Id);
            Assert.Equal("someone@cpaglobal.com" , userPasswordExpiryDetails[0].Email);
            Assert.True(userPasswordExpiryDetails[0].EmailBody.Contains(user.Name.FirstName));

            f.DocItemRunner.Received(1).Run(dataItem.Id, Arg.Any<Dictionary<string, object>>());
            Assert.True(userPasswordExpiryDetails[0].EmailBody.Contains(docItemResult));
        }
    }

    public class UserPasswordExpiryValidatorFixture : IFixture<UserPasswordExpiryValidator>
    {
        public UserPasswordExpiryValidator Subject { get; set; }
        public Func<DateTime> Now { get; set; }
        public IEmailValidator EmailValidator { get; set; }
        public IDocItemRunner DocItemRunner { get; set; }
        public UserPasswordExpiryValidatorFixture(InMemoryDbContext db)
        {
            Now = Substitute.For<Func<DateTime>>();
            EmailValidator = Substitute.For<IEmailValidator>();
            DocItemRunner = Substitute.For<IDocItemRunner>();
            Subject = new UserPasswordExpiryValidator(db, Now, EmailValidator, DocItemRunner);
            Now().Returns(Fixture.Today());
        }
    }

}
