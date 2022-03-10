using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.BulkCaseImport;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Ede;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class BatchSummaryControllerFacts
    {
        public class GetBatchIdentifier : FactBase
        {
            readonly ICommonQueryService _cqs = Substitute.For<ICommonQueryService>();

            [Fact]
            public void ShouldReturnBatchDetails()
            {
                var batchId = Fixture.Integer();
                var batchName = Fixture.String();

                new EdeSenderDetails
                {
                    SenderRequestIdentifier = batchName,
                    TransactionHeader = new EdeTransactionHeader
                    {
                        BatchId = batchId
                    }.In(Db)
                }.In(Db);

                var subject = new BatchSummaryViewController(Db, _cqs);

                var batch = subject.GetBatchIdentifier(batchId);

                Assert.Equal(batchId, batch.Id);
                Assert.Equal(batchName, batch.Name);
            }

            [Fact]
            public void ShouldReturnBatchDetailsWithTransactionCode()
            {
                var batchId = Fixture.Integer();
                var batchName = Fixture.String();
                var transactionReturnCode = Fixture.String();

                new EdeSenderDetails
                {
                    SenderRequestIdentifier = batchName,
                    TransactionHeader = new EdeTransactionHeader
                    {
                        BatchId = batchId
                    }.In(Db)
                }.In(Db);

                var subject = new BatchSummaryViewController(Db, _cqs);

                var batch = subject.GetBatchIdentifier(batchId, transactionReturnCode);

                Assert.Equal(batchId, batch.Id);
                Assert.Equal(batchName, batch.Name);
                Assert.Equal(transactionReturnCode, batch.TransReturnCode);
            }

            [Fact]
            public void ShouldReturnNotFound()
            {
                var subject = new BatchSummaryViewController(Db, _cqs);

                var batch = subject.GetBatchIdentifier(Fixture.Integer());

                Assert.IsType<HttpResponseMessage>(batch);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseMessage) batch).StatusCode);
            }
        }

        public class GetFilterDataForColumn : FactBase
        {
            [Fact]
            public void ShouldNotReturnFiltersIfDataDoesNotExists()
            {
                var commonQueryService = Substitute.For<ICommonQueryService>();
                commonQueryService.BuildCodeDescriptionObject(string.Empty, string.Empty).ReturnsForAnyArgs(new CodeDescription {Code = "Error", Description = "Error"});

                var batchId = Fixture.Integer();

                var subject = new BatchSummaryViewController(Db, commonQueryService);

                var r = subject.GetFilterDataForColumn("status", batchId).ToArray();

                Assert.False(r.Any());
            }

            [Fact]
            public void ShouldReturnFiltersIfDataExists()
            {
                var commonQueryService = Substitute.For<ICommonQueryService>();
                commonQueryService.BuildCodeDescriptionObject(string.Empty, string.Empty).ReturnsForAnyArgs(new CodeDescription {Code = "Error", Description = "Error"});

                var batchId = Fixture.Integer();

                new EdeBatchBuilder(Db, batchId, "Request", EdeBatchStatus.Processed)
                    .WithNewCase("12345", "AU", "T", null, "123", string.Empty, "New Title");

                var subject = new BatchSummaryViewController(Db, commonQueryService);

                var r = subject.GetFilterDataForColumn("status", batchId).ToArray();

                Assert.True(r.Any());
                Assert.Equal("Error", r[0].Code);
                Assert.Equal("Error", r[0].Description);
            }
        }

        public class GetMethod : FactBase
        {
            public GetMethod()
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.BuildCodeDescriptionObject(string.Empty, string.Empty).ReturnsForAnyArgs(new CodeDescription {Code = "Error", Description = "Error"});
            }

            ICommonQueryService CommonQueryService { get; }

            [Fact]
            public void MappedOfficialNumberHasHighestPriority()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);
                var builder = new EdeBatchBuilder(Db, 1, "Request_Id_567", EdeBatchStatus.Processed);
                builder.WithNewCase("1234", "AU", "P", null, null, "New Case")
                       .WithOfficialNumber("AUPat987654", 1, "N")
                       .WithOfficialNumber("ShouldNotReturn", 2, "N")
                       .WithOfficialNumber("ShouldNotReturn_Ede", null, null);

                var resultTransactions = ((IEnumerable<dynamic>) subject.Get(1).Data).First();

                Assert.Equal("AUPat987654", resultTransactions.OfficialNumber);
            }

            [Fact]
            public void ReturnsDetailsFromCase()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);

                var builder = new EdeBatchBuilder(Db, 1, "Request", EdeBatchStatus.Processed)
                    .WithNewCase("12345", "AU", "T", null, "123", string.Empty, "New Title");

                var @case =
                    Db.Set<Case>()
                      .First(
                             c =>
                                 c.Id ==
                                 builder.EdeSenderDetails.TransactionHeader.TransactionBodies.First().CaseDetails.CaseId);

                var result = subject.Get(1);
                var r = ((IEnumerable<dynamic>) result.Data).First();

                Assert.Equal("123", r.Id);
                Assert.Equal(@case.Irn, r.CaseReference);
                Assert.Equal("New Title", r.CaseTitle);
            }

            [Fact]
            public void ReturnsDetailsFromMatchedCase()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);

                var builder = new EdeBatchBuilder(Db, 1, "Request", EdeBatchStatus.Processed)
                    .WithMatchedCase("12345", "AU", "T", null, "123", string.Empty, "New Title");

                var @case =
                    Db.Set<Case>()
                      .First(
                             c =>
                                 c.Id ==
                                 builder.EdeSenderDetails.TransactionHeader.TransactionBodies.First()
                                        .CaseMatch.LiveCaseId);

                var result = subject.Get(1);
                var r = ((IEnumerable<dynamic>) result.Data).First();

                Assert.Equal("123", r.Id);
                Assert.Equal(@case.Irn, r.CaseReference);
                Assert.Equal("New Title", r.CaseTitle);
            }

            [Fact]
            public void ReturnsEdeDetails()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);
                new EdeBatchBuilder(Db, 1, "Request_Id_567", EdeBatchStatus.Processed)
                    .WithNewCase("1234", "AU", "P", null, null, TransactionReturnCodes.CaseAmended)
                    .WithNewCase("9876", "US", "TM", null, null, TransactionReturnCodes.CaseAmended);

                var result = subject.Get(1, "amendedCases");

                var firstTransaction = ((IEnumerable<dynamic>) result.Data).First();
                var secondTransaction = ((IEnumerable<dynamic>) result.Data).Last();

                Assert.Equal(2, result.Pagination.Total);

                Assert.Equal("1234", firstTransaction.CaseReference);
                Assert.Equal("AU", firstTransaction.Country);
                Assert.Equal("P", firstTransaction.PropertyType);
                Assert.Equal("Case Amended", firstTransaction.Result);

                Assert.Equal("9876", secondTransaction.CaseReference);
                Assert.Equal("US", secondTransaction.Country);
                Assert.Equal("TM", secondTransaction.PropertyType);
                Assert.Equal("Case Amended", secondTransaction.Result);
            }

            [Fact]
            public void ReturnsEdeDetailsForRejectedCases()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);
                new EdeBatchBuilder(Db, 1, "Request_Id_568", EdeBatchStatus.Processed)
                    .WithNewCase("1234", "AU", "P", null, null, TransactionReturnCodes.CaseDeleted)
                    .WithNewCase("9876", "US", "TM", null, null, TransactionReturnCodes.CaseReverted);

                var result = subject.Get(1, "rejectedCases");

                var firstTransaction = ((IEnumerable<dynamic>) result.Data).First();
                var secondTransaction = ((IEnumerable<dynamic>) result.Data).Last();

                Assert.Equal(2, result.Pagination.Total);

                Assert.Equal("1234", firstTransaction.CaseReference);
                Assert.Equal("AU", firstTransaction.Country);
                Assert.Equal("P", firstTransaction.PropertyType);
                Assert.Equal("Case Deleted Or Archived", firstTransaction.Result);

                Assert.Equal("9876", secondTransaction.CaseReference);
                Assert.Equal("US", secondTransaction.Country);
                Assert.Equal("TM", secondTransaction.PropertyType);
                Assert.Equal("Case Reversed", secondTransaction.Result);
            }

            [Fact]
            public void ReturnsEdeOfficialNumberWhenNoOther()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);
                var builder = new EdeBatchBuilder(Db, 1, "Request_Id_567", EdeBatchStatus.Processed);
                builder.WithNewCase("1234", "AU", "P", null, null, "New Case")
                       .WithOfficialNumber("EdeNumber987654", null, null)
                       .WithOfficialNumber("ShouldNotReturn", null, null);

                var resultTransactions = ((IEnumerable<dynamic>) subject.Get(1).Data).First();

                Assert.Equal("EdeNumber987654", resultTransactions.OfficialNumber);
            }

            [Fact]
            public void ReturnsListOfOutstandingIssues()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);
                var builder = new EdeBatchBuilder(Db, 1, "Request_Id_567", EdeBatchStatus.Processed);
                builder.WithNewCase("1234", "AU", "P", null, null, "New Case")
                       .WithTransactionIssue("Short Issue", null)
                       .WithTransactionIssue(null, "Long Issue");

                var resultTransactions = ((IEnumerable<dynamic>) subject.Get(1).Data).First();
                var issuesResult = ((IEnumerable<dynamic>) resultTransactions.Issues).ToArray();

                Assert.Equal(2, issuesResult.Count());
                Assert.Equal("Short Issue", issuesResult[0]);
                Assert.Equal("Long Issue", issuesResult[1]);
            }

            [Fact]
            public void ReturnsPagingInformation()
            {
                var subject = new BatchSummaryViewController(Db, CommonQueryService);
                var builder = new EdeBatchBuilder(Db, 1, "Request_Id_567", EdeBatchStatus.Processed);
                builder.WithNewCases(150);

                var result = subject.Get(1, null, new CommonQueryParameters {Skip = 0, Take = 50});

                Assert.Equal(150, result.Pagination.Total);
                Assert.Equal(50, ((IEnumerable<dynamic>) result.Data).Count());
            }

            [Fact]
            public void ShouldReturnMatchLevelOfMatchedCase()
            {
                var matchLevel = Fixture.String();

                var subject = new BatchSummaryViewController(Db, CommonQueryService);

                new EdeBatchBuilder(Db, 1, "Request_Id_567", EdeBatchStatus.Processed)
                    .WithMatchedCase("12345", "AU", "T", null, "123", string.Empty, "New Title", matchLevel);

                var resultTransactions = ((IEnumerable<dynamic>) subject.Get(1).Data).First();

                Assert.Equal(matchLevel, resultTransactions.Result);
            }
        }
    }
}