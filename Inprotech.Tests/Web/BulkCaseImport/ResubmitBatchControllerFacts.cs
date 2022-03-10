using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class ResubmitBatchControllerFacts
    {
        public class ResubmitBatchControllerFixture : IFixture<ResubmitBatchController>
        {
            readonly InMemoryDbContext _db;

            public ResubmitBatchControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                BatchProcessor = Substitute.For<IBulkLoadProcessing>();
                Subject = new ResubmitBatchController(db, BatchProcessor);
            }

            public IBulkLoadProcessing BatchProcessor { get; }

            public ResubmitBatchController Subject { get; }

            public ResubmitBatchControllerFixture WithEdeSenderDetails(int batchStatus = EdeBatchStatus.Unprocessed)
            {
                new EdeSenderDetails
                {
                    SenderRequestIdentifier = "12136513",
                    TransactionHeader = new EdeTransactionHeader
                    {
                        BatchId = 1,
                        BatchStatus = new TableCode(batchStatus, 128, "Processed")
                    }
                }.In(_db);

                return this;
            }
        }

        public class ResubmitBatch : FactBase
        {
            [Fact]
            public void PassesValidationIfNoExistingProcessRequests()
            {
                var fixture = new ResubmitBatchControllerFixture(Db).WithEdeSenderDetails();
                var result = fixture.Subject.ResubmitBatch(JObject.Parse("{batchId: 1}"));
                Assert.Equal("success", result.result);
                fixture.BatchProcessor.ReceivedWithAnyArgs(1).SubmitToEde(1);
            }

            [Fact]
            public void RejectsIfBatchIsOutputProduced()
            {
                var subject = new ResubmitBatchControllerFixture(Db).WithEdeSenderDetails(EdeBatchStatus.OutputProduced).Subject;
                var result = subject.ResubmitBatch(JObject.Parse("{batchId: 1}"));
                Assert.Equal("error", result.result);
            }

            [Fact]
            public void RejectsIfBatchIsProcessed()
            {
                var subject = new ResubmitBatchControllerFixture(Db).WithEdeSenderDetails(EdeBatchStatus.Processed).Subject;
                var result = subject.ResubmitBatch(JObject.Parse("{batchId: 1}"));
                Assert.Equal("error", result.result);
            }

            [Fact]
            public void RemovesRedundantProcessRequests()
            {
                new ProcessRequest
                {
                    Id = 1,
                    Context = ProcessRequestContexts.ElectronicDataExchange,
                    BatchId = 1,
                    Status = new TableCode((int) ProcessRequestStatus.Error, 140, "Error").In(Db)
                }.In(Db);

                new ProcessRequest
                {
                    Id = 2,
                    Context = ProcessRequestContexts.ElectronicDataExchange,
                    BatchId = 1,
                    Status = null
                }.In(Db);

                var subject = new ResubmitBatchControllerFixture(Db).WithEdeSenderDetails().Subject;

                subject.ResubmitBatch(JObject.Parse("{batchId: 1}"));

                var processRequests = Db.Set<ProcessRequest>().Where(pr => pr.BatchId == 1);
                Assert.Empty(processRequests);
            }

            [Fact]
            public void ReturnsAnErrorIfInProgress()
            {
                new ProcessRequest
                {
                    Id = 1,
                    Context = ProcessRequestContexts.ElectronicDataExchange,
                    BatchId = 1,
                    Status = new TableCode((int) ProcessRequestStatus.Processing, 140, "Processing").In(Db)
                }.In(Db);

                var subject = new ResubmitBatchControllerFixture(Db).WithEdeSenderDetails().Subject;
                var result = subject.ResubmitBatch(JObject.Parse("{batchId: 1}"));
                Assert.Equal("error", result.result);
            }
        }
    }
}