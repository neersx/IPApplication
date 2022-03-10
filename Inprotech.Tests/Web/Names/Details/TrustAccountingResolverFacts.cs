using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Names.Details;
using InprotechKaizen.Model.Components.Names.TrustAccounting;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Tests.Web.Names.Details
{
    public class TrustAccountingResolverFacts
    {
        public class TrustAccountingResolverFixture : IFixture<TrustAccountingResolver>
        {
            public TrustAccountingResolverFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                TrustAccounting = Substitute.For<ITrustAccounting>();
                CommonQueryService = Substitute.For<ICommonQueryService>();
                NameAccessSecurity = Substitute.For<INameAccessSecurity>();
                Subject = new TrustAccountingResolver(DbContext, PreferredCultureResolver, TrustAccounting, CommonQueryService, NameAccessSecurity);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ITrustAccounting TrustAccounting { get; set; }
            public ICommonQueryService CommonQueryService { get; set; }
            public InMemoryDbContext DbContext { get; set; }
            public TrustAccountingResolver Subject { get; }
            public static INameAccessSecurity NameAccessSecurity { get; set; }
        }

        public class GetNameViewRequiredData : FactBase
        {
            const int NameId = 1234;

            [Fact]
            public async Task ShouldThrowBadRequestExceptionIfRequestInvalid()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () =>
                                                                                {
                                                                                    var fixture = new TrustAccountingResolverFixture(Db);
                                                                                    await fixture.Subject.Resolve(0, new CommonQueryParameters());
                                                                                });

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task VerifyTrustAccountingResultsWithValidNameId()
            {
                var f = new TrustAccountingResolverFixture(Db);
                int entityKey = Fixture.Integer();
                var name = new Name(NameId).In(Db);
                var entity = new Name(entityKey).In(Db);

                var trustAccountingList = new List<TrustAccounts> { new TrustAccounts { EntityKey = entity.Id } };
                f.TrustAccounting.GetTrustAccountingData(name.Id, Arg.Any<string>())
                 .Returns(trustAccountingList);
                var req = new CommonQueryParameters {Skip = 0, Take = 10};
                var result = await f.Subject.Resolve(NameId, req);
                Assert.NotNull(result.Result.Data);
                Assert.Equal(1, result.Result.Pagination.Total);
            }

            [Fact]
            public async Task VerifyTrustAccountingResultsWithValidPagination()
            {
                var f = new TrustAccountingResolverFixture(Db);
                int entityKey = Fixture.Integer();
                var name = new Name(NameId).In(Db);
                var entity = new Name(entityKey).In(Db);

                var trustAccountingList = new List<TrustAccounts>
                {
                    new TrustAccounts {EntityKey = entity.Id, LocalBalance = 1},
                    new TrustAccounts {EntityKey = entity.Id, LocalBalance = 1},
                    new TrustAccounts {EntityKey = entity.Id, LocalBalance = 1},
                    new TrustAccounts {EntityKey = entity.Id, LocalBalance = 1},
                    new TrustAccounts {EntityKey = entity.Id, LocalBalance = 1},
                    new TrustAccounts {EntityKey = entity.Id, LocalBalance = 1}
                };
                f.TrustAccounting.GetTrustAccountingData(name.Id, Arg.Any<string>())
                 .Returns(trustAccountingList);
                var req = new CommonQueryParameters { Skip = 1, Take = 4 };
                var result = await f.Subject.Resolve(NameId, req);
                Assert.NotNull(result.Result.Data);
                Assert.Equal(1, result.Result.Pagination.Total);
                Assert.Equal((decimal)6.00, result.TotalLocalBalance);
            }

            [Fact]
            public async Task VerifyTrustAccountingDetailsResultsWithValidPagination()
            {
                var f = new TrustAccountingResolverFixture(Db);
                var nameId = Fixture.Integer();
                var bankId = Fixture.Integer();
                var bankSeqId = Fixture.Integer();
                var entityId = Fixture.Integer();

                var trustAccountingDetails = new List<TrustAccountingDetails>
                {
                    new TrustAccountingDetails {TraderId = 10 , Date = DateTime.Today, Description = Fixture.String(), LocalBalance = (decimal)10.10, LocalValue = (decimal)20.50, LocalCurrency = "AUD"},
                    new TrustAccountingDetails {TraderId = 10 , Date = DateTime.Today, Description = Fixture.String(), LocalBalance = (decimal)10.10, LocalValue = (decimal)20.50, LocalCurrency = "AUD"},
                    new TrustAccountingDetails {TraderId = 10 , Date = DateTime.Today, Description = Fixture.String(), LocalBalance = (decimal)10.10, LocalValue = (decimal)20.50, LocalCurrency = "AUD"},
                    new TrustAccountingDetails {TraderId = 10 , Date = DateTime.Today, Description = Fixture.String(), LocalBalance = (decimal)10.10, LocalValue = (decimal)20.50, LocalCurrency = "AUD"},
                    new TrustAccountingDetails {TraderId = 10 , Date = DateTime.Today, Description = Fixture.String(), LocalBalance = (decimal)10.10, LocalValue = (decimal)20.50, LocalCurrency = "AUD"},
                    new TrustAccountingDetails {TraderId = 10 , Date = DateTime.Today, Description = Fixture.String(), LocalBalance = (decimal)10.10, LocalValue = (decimal)20.50, LocalCurrency = "AUD"}
                };
                f.TrustAccounting.GetTrustAccountingDetails(nameId, bankId, bankSeqId, entityId,Arg.Any<string>()).Returns(trustAccountingDetails);
                var param = new CommonQueryParameters {Skip = 0, Take = 5};
                var result = await f.Subject.Details(nameId, bankId, bankSeqId, entityId, param);

                Assert.NotNull(result.Result.Data);
                Assert.Equal(6, result.Result.Pagination.Total);
                Assert.Equal((decimal)60.60, result.TotalLocalBalance);
                Assert.Equal((decimal)123.00, result.TotalLocalValue);
            }
        }
    }
}