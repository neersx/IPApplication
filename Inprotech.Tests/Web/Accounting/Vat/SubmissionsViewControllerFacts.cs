using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Inprotech.Contracts.DocItems;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.VatReturns;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Vat
{
    public class SubmissionsViewControllerFacts
    {
        public class SubmissionsViewControllerFixture : IFixture<SubmissionsViewController>
        {
            public SubmissionsViewControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                HmrcAuthenticator = Substitute.For<IHmrcAuthenticator>();
                HmrcClient = Substitute.For<IHmrcClient>();
                DocItemRunner = Substitute.For<IDocItemRunner>();
                VatReturnStore = Substitute.For<IVatReturnStore>();
                VatReturnExporter = Substitute.For<IVatReturnsExporter>();
                GuidFactory = Substitute.For<Func<Guid>>();
                HmrcTokens = Substitute.For<IHmrcTokenResolver>();

                Subject = new SubmissionsViewController(Db, HmrcAuthenticator, HmrcClient, DocItemRunner, VatReturnStore, VatReturnExporter, GuidFactory, HmrcTokens);
            }

            public Func<Guid> GuidFactory { get; set; }

            InMemoryDbContext Db { get; }
            public IHmrcAuthenticator HmrcAuthenticator { get; set; }
            public IHmrcClient HmrcClient { get; set; }
            public IDocItemRunner DocItemRunner { get; set; }
            public IVatReturnStore VatReturnStore { get; set; }
            public IVatReturnsExporter VatReturnExporter { get; set; }
            public IHmrcTokenResolver HmrcTokens { get; set; }
            public SubmissionsViewController Subject { get; }
        }

        public class GetMethod : FactBase
        {
            [Theory]
            [InlineData(544333.33, true)]
            [InlineData(544333.33, false)]
            [InlineData(1.22, true)]
            [InlineData(1.22, false)]
            public void VatDocItemIsCalledCorrectly(decimal returnValue, bool useItem1)
            {
                var item1 = new DocItem
                {
                    Id = 1,
                    Name = KnownVatDocItems.Box1,
                    Description = "Doc Item Vat Box 1",
                    DateCreated = Fixture.Date(),
                    DateUpdated = Fixture.Date(),
                    CreatedBy = "sysadm",
                    ItemType = 1
                }.In(Db);
                var item1ReturnValue = returnValue;
                var item2 = new DocItem
                {
                    Id = 2,
                    Name = KnownVatDocItems.Box2,
                    Description = "Doc Item Vat Box 2",
                    ItemType = 1,
                    DateCreated = Fixture.Date(),
                    DateUpdated = Fixture.Date(),
                    CreatedBy = "sysadm"
                }.In(Db);

                var dataSet = new DataSet();
                var dataTable = new DataTable();
                dataTable.Columns.Add(new DataColumn("returnValue", typeof(decimal)));
                dataTable.Rows.Add(item1ReturnValue);
                dataSet.Tables.Add(dataTable);
                var f = new SubmissionsViewControllerFixture(Db);
                f.DocItemRunner.Run(useItem1 ? item1.Id : item2.Id, Arg.Any<IDictionary<string, object>>()).Returns(dataSet);
                var entityNo = Fixture.Integer();
                var fromDate = Fixture.PastDate();
                var toDate = Fixture.FutureDate();
                var query = new VatDataRetrievalParams {VatBoxNumber = useItem1 ? 1 : 2, EntityNameNo = entityNo, FromDate = fromDate, ToDate = toDate};
                var result = f.Subject.GetVatData(query);
                Assert.Equal(item1ReturnValue, result.Value);
                f.DocItemRunner.Received(1)
                 .Run(useItem1
                          ? item1.Id
                          : item2.Id,
                      Arg.Is<Dictionary<string, object>>(_ => (int) _["pnEntityNo"] == entityNo &&
                                                              (DateTime) _["pdTransDateStart"] == fromDate &&
                                                              (DateTime) _["pdTransDateEnd"] == toDate));
            }

            [Fact]
            public void ReturnsEntityNames()
            {
                var name1 = new Name {LastName = "ABC"}.In(Db);
                var name2 = new Name {LastName = "AAB"}.In(Db);
                var name3 = new Name {LastName = "DEF", TaxNumber = Fixture.String("TAX")}.In(Db);
                new SpecialName(true, name1).In(Db);
                new SpecialName(false, name2).In(Db);
                new SpecialName(true, name3).In(Db);
                var f = new SubmissionsViewControllerFixture(Db);
                var result = f.Subject.Get();
                List<SubmissionsViewController.EntityName> entities = result.EntityNames;
                Assert.Equal(2, entities.Count);
                Assert.Equal(name1.Id, entities.First().Id);
                Assert.Null(entities.First().TaxCode);
                Assert.Equal(name3.Id, entities.Last().Id);
                Assert.Equal(name3.TaxNumber, entities.Last().TaxCode);
            }

            [Fact]
            public void VatDocItemReturnNullWhenItemNotFound()
            {
                var vatBox = Db.Set<DocItem>().SingleOrDefault(v => v.Name == KnownVatDocItems.Box6);
                if (vatBox != null)
                {
                    Db.Set<DocItem>().Remove(vatBox);
                    Db.SaveChanges();
                }

                var f = new SubmissionsViewControllerFixture(Db);
                var query = new VatDataRetrievalParams {VatBoxNumber = 6};
                var result = f.Subject.GetVatData(query);
                Assert.Null(result.Value);
            }
        }

        public class Authorise : FactBase
        {
            public class GetObligations : FactBase
            {
                [Fact]
                public async Task RaisesExceptionWhereNoFilters()
                {
                    var f = new SubmissionsViewControllerFixture(Db);
                    var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetObligations());
                    Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                    await f.HmrcClient.DidNotReceive().RetrieveObligations(Arg.Any<VatObligationsQuery>(), Arg.Any<string>(), Arg.Any<HttpRequestMessage>());
                }

                [Fact]
                public async Task RaisesExceptionWhereNoTaxNumber()
                {
                    var f = new SubmissionsViewControllerFixture(Db);
                    await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.GetObligations(new VatObligationsQuery()));
                    await f.HmrcClient.DidNotReceive().RetrieveObligations(Arg.Any<VatObligationsQuery>(), Arg.Any<string>(), Arg.Any<HttpRequestMessage>());
                }

                [Fact]
                public async Task RaisesExceptionWhereNoToken()
                {
                    var f = new SubmissionsViewControllerFixture(Db);
                    var controllerContext = new HttpControllerContext();
                    var request = new HttpRequestMessage();
                    controllerContext.Request = request;
                    f.Subject.ControllerContext = controllerContext;
                    f.HmrcTokens.Resolve(Arg.Any<string>()).Returns(new HmrcTokens {AccessToken = null, RefreshToken = null});
                    var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetObligations(new VatObligationsQuery {TaxNo = Fixture.String()}));
                    Assert.Equal(HttpStatusCode.Unauthorized, exception.Response.StatusCode);
                    await f.HmrcClient.DidNotReceive().RetrieveObligations(Arg.Any<VatObligationsQuery>(), Arg.Any<string>(), Arg.Any<HttpRequestMessage>());
                }

                [Fact]
                public async Task RefreshesTokenWhenUnauthorised()
                {
                    var q = new VatObligationsQuery {TaxNo = Fixture.String()};
                    var accessToken1 = Fixture.String();
                    var accessToken2 = Fixture.String();
                    var refreshToken1 = Fixture.String();
                    var refreshToken2 = Fixture.String();
                    var periodKey = Fixture.String();
                    var obligations = new List<VatObligation> {new VatObligation {EntityNameNo = 12345, PeriodKey = periodKey}};
                    var f = new SubmissionsViewControllerFixture(Db);

                    var controllerContext = new HttpControllerContext();
                    var request = new HttpRequestMessage();
                    controllerContext.Request = request;
                    f.Subject.ControllerContext = controllerContext;
                    f.HmrcTokens.Resolve(Arg.Any<string>()).Returns(new HmrcTokens {AccessToken = accessToken1, RefreshToken = refreshToken1});

                    f.HmrcClient.RetrieveObligations(Arg.Any<VatObligationsQuery>(), Arg.Any<string>(), Arg.Any<HttpRequestMessage>()).Returns(new ObligationsResponse {Status = HttpStatusCode.Unauthorized, Data = obligations});
                    f.HmrcAuthenticator.RefreshToken(refreshToken1, Arg.Any<string>()).Returns(new AuthToken {AccessToken = accessToken2, RefreshToken = refreshToken2});
                    var result = await f.Subject.GetObligations(q);
                    await f.HmrcAuthenticator.Received(1).RefreshToken(refreshToken1, Arg.Any<string>());
                    await f.HmrcClient.Received(1).RetrieveObligations(q, accessToken1, request);
                    await f.HmrcClient.Received(1).RetrieveObligations(q, accessToken2, request);
                    Assert.Equal(accessToken2, result.Tokens.AccessToken);
                    Assert.Equal(refreshToken2, result.Tokens.RefreshToken);
                    Assert.Equal(periodKey, result.Data.Data[0].PeriodKey);
                }

                [Fact]
                public async Task RetrievesObligations()
                {
                    var q = new VatObligationsQuery {TaxNo = Fixture.String()};
                    var accessToken = Fixture.String();
                    var refreshToken = Fixture.String();
                    var periodKey = Fixture.String();
                    var obligations = new List<VatObligation> {new VatObligation {EntityNameNo = 12345, PeriodKey = periodKey}};
                    var f = new SubmissionsViewControllerFixture(Db);
                    var controllerContext = new HttpControllerContext();
                    var request = new HttpRequestMessage();
                    f.HmrcTokens.Resolve(Arg.Any<string>()).Returns(new HmrcTokens {AccessToken = accessToken, RefreshToken = refreshToken});
                    controllerContext.Request = request;
                    f.Subject.ControllerContext = controllerContext;
                    f.HmrcClient.RetrieveObligations(Arg.Any<VatObligationsQuery>(), Arg.Any<string>(), Arg.Any<HttpRequestMessage>()).Returns(new ObligationsResponse {Status = HttpStatusCode.OK, Data = obligations});
                    var result = await f.Subject.GetObligations(q);
                    await f.HmrcClient.Received(1).RetrieveObligations(q, accessToken, request);
                    Assert.Equal(accessToken, result.Tokens.AccessToken);
                    Assert.Equal(refreshToken, result.Tokens.RefreshToken);
                    Assert.Equal(periodKey, result.Data.Data[0].PeriodKey);
                }

                [Fact]
                public async Task ReturnsRedirectUrl()
                {
                    var f = new SubmissionsViewControllerFixture(Db);
                    var response = Substitute.For<HttpWebResponse>();
                    var vrn = Fixture.String();
                    f.HmrcAuthenticator.GetAuthCode(Arg.Any<string>()).Returns(response);
                    await f.Subject.Authorise(vrn);
                    await f.HmrcAuthenticator.Received(1).GetAuthCode(Arg.Any<string>());
                }
            }
        }

        public class Submit : FactBase
        {
            [Fact]
            public async Task SubmitsVatReturnAndStoresResponseAndGeneratesPdf()
            {
                var vatValues = new[]
                {
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture),
                    Fixture.Decimal().ToString(CultureInfo.InvariantCulture)
                };
                var vatNo = Fixture.String();
                var accessToken = Fixture.String();
                var periodKey = Fixture.String();
                var entityNo = Fixture.Integer();
                var guid = Fixture.String();
                var request = new VatSubmissionRequest
                {
                    VatNo = vatNo, AccessToken = accessToken, VatValues = vatValues, EntityNo = entityNo.ToString(), PeriodKey = periodKey
                };

                var controllerContext = new HttpControllerContext();
                var requestHeader = new HttpRequestMessage();
                controllerContext.Request = requestHeader;
                var f = new SubmissionsViewControllerFixture(Db);
                f.HmrcTokens.Resolve(Arg.Any<string>()).Returns(new HmrcTokens { AccessToken = accessToken });
                f.HmrcClient.SubmitVatReturn(Arg.Any<VatReturnData>(), Arg.Any<string>(), Arg.Any<string>(), requestHeader).Returns(new {IsSuccessful = false, Data = new {Code = "ErrorCode", Message = "ErrorMessage"}});
                f.VatReturnExporter.ExportVatReturnToPdf(Arg.Any<object>(), Arg.Any<object>(), Arg.Any<bool>()).Returns(guid);
                f.Subject.ControllerContext = controllerContext;
                var result = await f.Subject.Submit(request);
                await f.HmrcClient.Received(1).SubmitVatReturn(Arg.Any<VatReturnData>(), request.VatNo, request.AccessToken, requestHeader);
                f.VatReturnStore.Received(1).Add(entityNo, periodKey, result.Data, false, request.VatNo);
                Assert.Equal("ErrorCode", result.Data.Code);
                Assert.Equal("ErrorMessage", result.Data.Message);
                f.VatReturnExporter.Received(1).ExportVatReturnToPdf(Arg.Any<dynamic>(), Arg.Any<dynamic>(), false);
                Assert.Equal(result.PdfStorageId, guid);
            }
        }

        public class GetVatReturn : FactBase
        {
            [Fact]
            public async Task RetrievesStoreVatDetailsFromHmrcAndGeneratesPdf()
            {
                var vatNo = Fixture.String();
                var accessToken = Fixture.String();
                var periodKey = Fixture.String();
                var controllerContext = new HttpControllerContext();
                var request = new HttpRequestMessage();
                var guid = Fixture.String();
                controllerContext.Request = request;
                var f = new SubmissionsViewControllerFixture(Db);
                f.HmrcTokens.Resolve(Arg.Any<string>()).Returns(new HmrcTokens { AccessToken = accessToken });
                var vatSubmissionRequest = new VatSubmissionRequest {AccessToken = accessToken, EntityNo = "1", PeriodKey = periodKey, VatNo = vatNo};
                f.Subject.ControllerContext = controllerContext;
                var vatData = new[]
                {
                    Fixture.Decimal(),
                    Fixture.Decimal(),
                    Fixture.Decimal(),
                    Fixture.Decimal(),
                    Fixture.Decimal(),
                    Fixture.Decimal(),
                    Fixture.Decimal(),
                    Fixture.Decimal(),
                    Fixture.Decimal()
                };
                f.HmrcClient.GetVatReturn(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<HttpRequestMessage>())
                 .Returns(new
                 {
                     Status = HttpStatusCode.OK,
                     Data = vatData
                 });
                f.VatReturnStore.GetVatReturnResponse(Arg.Any<string>(), Arg.Any<string>())
                 .Returns(new VatReturn
                 {
                     Data = "{\"processingDate\":\"2019-03-08T05:36:09.499Z\",\"paymentIndicator\":\"DD\",\"formBundleNumber\":\"989029132190\",\"chargeRefNumber\":\"i5ITkeJ9trOGH0zs\"}",
                     IsSubmitted = true,
                     PeriodId = "18A2",
                     EntityId = 1
                 });
                f.VatReturnExporter.ExportVatReturnToPdf(Arg.Any<object>(), Arg.Any<object>(), Arg.Any<bool>()).Returns(guid);
                var result = await f.Subject.GetVatReturn(vatSubmissionRequest);

                await f.HmrcClient.Received(1).GetVatReturn(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<HttpRequestMessage>());
                f.VatReturnExporter.Received(1).ExportVatReturnToPdf(Arg.Any<dynamic>(), Arg.Any<dynamic>(), true);
                Assert.Equal(result.PdfStorageId, guid);
                Assert.Equal(HttpStatusCode.OK, result.VatReturnData.Status);
                Assert.Equal(vatData[0], result.VatReturnData.Data[0]);
                Assert.Equal(vatData[1], result.VatReturnData.Data[1]);
                Assert.Equal(vatData[2], result.VatReturnData.Data[2]);
                Assert.Equal(vatData[3], result.VatReturnData.Data[3]);
                Assert.Equal(vatData[4], result.VatReturnData.Data[4]);
                Assert.Equal(vatData[5], result.VatReturnData.Data[5]);
                Assert.Equal(vatData[6], result.VatReturnData.Data[6]);
                Assert.Equal(vatData[7], result.VatReturnData.Data[7]);
                Assert.Equal(vatData[8], result.VatReturnData.Data[8]);
            }
        }

        public class VatLogs : FactBase
        {
            [Fact]
            public void RetrieveTheLogs()
            {
                var f = new SubmissionsViewControllerFixture(Db);
                var error1 = new VatReturn
                {
                    Data = "{\"code\":\"BUSINESS_ERROR\",\"message\":\"Business validation error\",\"errors\":[{\"code\":\"DUPLICATE_SUBMISSION\",\"message\":\"The VAT return was already submitted for the given period.\"}]}",
                    IsSubmitted = false,
                    PeriodId = "18A1",
                    EntityId = 2,
                    LastModified = Fixture.Today()
                }.In(Db);
                var error2 = new VatReturn
                {
                    Data = "{\"code\":\"BIG_BUSINESS_ERROR\",\"message\":\"Big Business validation error\",\"errors\":[{\"code\":\"BIG_DUPLICATE_SUBMISSION\",\"message\":\"The BIG VAT return was already submitted for the given period.\"}]}",
                    IsSubmitted = false,
                    PeriodId = "18A1",
                    EntityId = 2,
                    LastModified = Fixture.PastDate()
                }.In(Db);
                var errors = new[] {error1, error2};
                f.VatReturnStore.GetLogData(Arg.Any<string>(), Arg.Any<string>()).Returns(errors);

                var result = f.Subject.VatLogs(new VatSubmissionRequest()).ToArray();

                Assert.Equal(error1.LastModified, result[0].Date);
                Assert.Equal("BUSINESS_ERROR", result[0].Message.code.ToString());
                Assert.Equal(error2.LastModified, result[1].Date);
                Assert.Equal("BIG_BUSINESS_ERROR", result[1].Message.code.ToString());
            }
        }

        public class ExportToPdf : FactBase
        {
            [Fact]
            public void CorrectlyCreatesPdfAndReturnUrl()
            {
                var exportArgs = new VatPdfExportRequest
                {
                    PdfId = Fixture.String(),
                    EntityName = Fixture.String(),
                    FromDate = Fixture.String(),
                    ToDate = Fixture.String()
                };

                var exportArgsString = Convert.ToBase64String(Encoding.ASCII.GetBytes(JsonConvert.SerializeObject(exportArgs)));
                var f = new SubmissionsViewControllerFixture(Db);

                var result = f.Subject.ExportToPdf(exportArgsString,"vatdata.pdf");

                Assert.Equal(new MediaTypeHeaderValue("application/pdf"), result.Content.Headers.ContentType);
                Assert.Equal(HttpStatusCode.OK, result.StatusCode);
            }
        }
    }
}