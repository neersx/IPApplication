using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications
{
    public class ExternalApplicationTokenControllerFacts
    {
        public class GetExternalApplicationsMethod : FactBase
        {
            dynamic CreateData()
            {
                var externalApp1 = new ExternalApplication {Name = "XternalSystem", Code = "XST"}.In(Db);
                var externalAppToken1 = new ExternalApplicationToken
                {
                    ExternalApplicationId = externalApp1.Id,
                    Token = "ABCD",
                    IsActive = true,
                    ExpiryDate = DateTime.Today.AddMonths(10),
                    CreatedBy = -1,
                    CreatedOn = DateTime.Today
                }.In(Db);
                externalApp1.ExternalApplicationToken = externalAppToken1;

                var externalApp2 = new ExternalApplication {Name = "Trinogy", Code = "TRN"}.In(Db);
                var externalAppToken2 = new ExternalApplicationToken
                {
                    ExternalApplicationId = externalApp2.Id,
                    Token = "TTTT",
                    IsActive = false,
                    ExpiryDate = null,
                    CreatedBy = -1,
                    CreatedOn = DateTime.Today
                }.In(Db);
                externalApp2.ExternalApplicationToken = externalAppToken2;

                return new
                {
                    externalApp1,
                    externalApp2
                };
            }

            [Fact]
            public void ReturnsExternalApplicationsInformationInNameAscendingOrder()
            {
                var data = CreateData();
                var externalApp = data.externalApp2;

                var result = ((IEnumerable<object>) new ExternalApplicationTokenControllerFixture(Db).Subject.GetExternalApplications().ExternalApps).First();

                var t = result.GetType();

                Assert.Equal(externalApp.Name, t.GetProperty("Name").GetValue(result, null));
                Assert.Equal(externalApp.Code, t.GetProperty("Code").GetValue(result, null));
                Assert.Equal(externalApp.ExternalApplicationToken.Token, t.GetProperty("Token").GetValue(result, null));
                Assert.Equal(externalApp.ExternalApplicationToken.ExpiryDate, t.GetProperty("ExpiryDate").GetValue(result, null));
                Assert.Equal(externalApp.ExternalApplicationToken.IsActive, t.GetProperty("IsActive").GetValue(result, null));
            }
        }

        public class GenerateTokenMethod : FactBase
        {
            [Fact]
            public void ReturnsNewTokenIfTokenAlreadyExists()
            {
                const string existingToken = "A1V2";
                var externalApp = new ExternalApplication().In(Db);
                externalApp.ExternalApplicationToken = new ExternalApplicationToken {ExternalApplicationId = externalApp.Id, Token = existingToken}.In(Db);

                var result = new ExternalApplicationTokenControllerFixture(Db).Subject.GenerateToken(externalApp.Id);

                var t = result.GetType();
                var changedToken = t.GetProperty("Token").GetValue(result, null);
                Assert.NotNull(changedToken);
                Assert.NotEqual(existingToken, changedToken);
            }

            [Fact]
            public void ReturnsTokenIfNotAlreadyThere()
            {
                var externalApp = new ExternalApplication().In(Db);
                var result = new ExternalApplicationTokenControllerFixture(Db).Subject.GenerateToken(externalApp.Id);

                var t = result.GetType();
                Assert.NotNull(t.GetProperty("Token").GetValue(result, null));
            }

            [Fact]
            public void ShouldThrowExceptionIfWrongExternalApplicationIdIsProvided()
            {
                var exception =
                    Record.Exception(() => { new ExternalApplicationTokenControllerFixture(Db).Subject.GenerateToken(Fixture.Integer()); });

                Assert.IsType<HttpException>(exception);
                Assert.Equal("Unable to generate token for non-existent external application.", exception.Message);
            }
        }

        public class GetExternalApplicationTokenMethod : FactBase
        {
            [Fact]
            public void ReturnsExternalApplicationTokenInformation()
            {
                var externalApp = new ExternalApplication {Name = "Trinogy", Code = "TRN"}.In(Db);
                var externalAppToken = new ExternalApplicationToken
                {
                    ExternalApplicationId = externalApp.Id,
                    Token = "ABCD",
                    IsActive = true,
                    ExpiryDate = DateTime.Today.AddMonths(10),
                    CreatedBy = -1,
                    CreatedOn = DateTime.Today
                }.In(Db);
                externalApp.ExternalApplicationToken = externalAppToken;
                var result = new ExternalApplicationTokenControllerFixture(Db).Subject.GetExternalApplicationToken(externalApp.Id);
                var t = result.GetType();
                Assert.Equal(externalApp.Id, t.GetProperty("ExternalApplicationId").GetValue(result, null));
                Assert.Equal(externalApp.Name, t.GetProperty("Name").GetValue(result, null));
                Assert.Equal(externalApp.Code, t.GetProperty("Code").GetValue(result, null));
                Assert.Equal(externalApp.ExternalApplicationToken.Token, t.GetProperty("Token").GetValue(result, null));
                if (externalApp.ExternalApplicationToken.ExpiryDate != null)
                {
                    Assert.Equal(externalApp.ExternalApplicationToken.ExpiryDate.Value.ToString("dd-MMM-yyyy"), t.GetProperty("ExpiryDate").GetValue(result, null));
                }

                Assert.Equal(externalApp.ExternalApplicationToken.IsActive, t.GetProperty("IsActive").GetValue(result, null));
            }

            [Fact]
            public void ShouldThrowExceptionIfWrongExternalApplicationIdIsProvided()
            {
                var exception =
                    Record.Exception(() => { new ExternalApplicationTokenControllerFixture(Db).Subject.SaveChanges(new ExternalApplicationToken {ExternalApplicationId = 1}); });

                Assert.IsType<HttpException>(exception);
                Assert.Equal("Unable to update a non-existent external application token.", exception.Message);
            }
        }

        public class SaveChangesMethod : FactBase
        {
            [Fact]
            public void EditExternalApplicationTokenFields()
            {
                var externalApp = new ExternalApplication().In(Db);
                externalApp.ExternalApplicationToken = new ExternalApplicationToken {ExternalApplicationId = externalApp.Id, Token = "A1V2"}.In(Db);

                var input = new ExternalApplicationToken {ExternalApplicationId = externalApp.Id, ExpiryDate = DateTime.Today.AddMonths(12), IsActive = true};

                var result = new ExternalApplicationTokenControllerFixture(Db).Subject.SaveChanges(input);

                var t = result.GetType();

                Assert.Equal(t.GetProperty("Result").GetValue(result, null), "success");
                Assert.Equal(externalApp.ExternalApplicationToken.ExpiryDate, DateTime.Today.AddMonths(12));
                Assert.True(externalApp.ExternalApplicationToken.IsActive);
            }

            [Fact]
            public void ShouldThrowExceptionIfWrongExternalApplicationIdIsProvided()
            {
                var exception =
                    Record.Exception(() => { new ExternalApplicationTokenControllerFixture(Db).Subject.SaveChanges(new ExternalApplicationToken {ExternalApplicationId = 1}); });

                Assert.IsType<HttpException>(exception);
                Assert.Equal("Unable to update a non-existent external application token.", exception.Message);
            }
        }

        public class ExternalApplicationTokenControllerFixture : IFixture<ExternalApplicationTokenController>
        {
            readonly InMemoryDbContext _db;

            public ExternalApplicationTokenControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User("fee-earner", false));

                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());
            }

            public ISecurityContext SecurityContext { get; }
            public Func<DateTime> SystemClock { get; }

            public ExternalApplicationTokenController Subject => new ExternalApplicationTokenController(_db,
                                                                                                        SecurityContext,
                                                                                                        SystemClock);
        }
    }
}