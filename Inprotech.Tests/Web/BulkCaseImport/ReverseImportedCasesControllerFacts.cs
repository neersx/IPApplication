using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Processing;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class ReverseImportedCasesControllerFacts : FactBase
    {
        public ReverseImportedCasesControllerFacts()
        {
            var user = new User().In(Db);
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(user);
            _subject = new ReverseImportedCasesController(Db, securityContext, _asyncCommandScheduler);
        }

        readonly IAsyncCommandScheduler _asyncCommandScheduler = Substitute.For<IAsyncCommandScheduler>();

        readonly ReverseImportedCasesController _subject;

        [Theory]
        [InlineData(EdeBatchStatus.Unprocessed)]
        [InlineData(EdeBatchStatus.Processed)]
        public async Task ShouldDispatchAsyncCommandForTheBatch(int allowedBatchStatus)
        {
            var batchId = Fixture.Integer();
            var batch = JObject.FromObject(new {batchId});
            var batchStatus = new TableCode(allowedBatchStatus, (short) TableTypes.EDEBatchStatus, Fixture.String()).In(Db);

            new EdeTransactionHeader
            {
                BatchId = batchId,
                BatchStatus = batchStatus
            }.In(Db);

            var r = await _subject.Reverse(batch);

            Assert.Equal("success", r.Result);

            _asyncCommandScheduler.Received(1)
                                  .ScheduleAsync("apps_ReverseCaseImportBatch",
                                                 Arg.Is<Dictionary<string, object>>(x => x.ContainsValue(batchId)))
                                  .IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldPreventReverseWhenExistingProcessRequestFound(bool hasProcessingStatus)
        {
            var batchId = Fixture.Integer();
            var batch = JObject.FromObject(new {batchId});
            var processingStatus = new TableCode((int) ProcessRequestStatus.Processing, (short) TableTypes.EDEBatchStatus, Fixture.String()).In(Db);

            new EdeTransactionHeader {BatchId = batchId}.In(Db);

            new ProcessRequest
            {
                BatchId = batchId,
                Context = ProcessRequestContexts.ElectronicDataExchange,
                RequestType = "EDE Resubmit Batch",
                Status = hasProcessingStatus ? processingStatus : null
            }.In(Db);

            var r = await _subject.Reverse(batch);

            Assert.Equal("error", r.Result);
            Assert.Equal("batch-already-being-reversed", r.ErrorCode);
        }

        [Fact]
        public async Task ShouldDispatchAsyncCommandAndDeleteErrorBatchProcess()
        {
            var batchId = Fixture.Integer();
            var batch = JObject.FromObject(new {batchId});
            var batchStatus = new TableCode(EdeBatchStatus.Unprocessed, (short) TableTypes.EDEBatchStatus, Fixture.String()).In(Db);
            var errorProcessStatus = new TableCode((int) ProcessRequestStatus.Error, (short) TableTypes.ProcessRequestStatus, "Error").In(Db);

            new EdeTransactionHeader
            {
                BatchId = batchId,
                BatchStatus = batchStatus
            }.In(Db);

            new ProcessRequest
            {
                BatchId = batchId,
                Context = ProcessRequestContexts.ElectronicDataExchange,
                RequestType = "EDE Resubmit Batch",
                Status = errorProcessStatus,
                StatusMessage = "error"
            }.In(Db);

            var r = await _subject.Reverse(batch);

            Assert.Equal("success", r.Result);

            Assert.Empty(Db.Set<ProcessRequest>().Where(_ => _.BatchId == batchId));

            _asyncCommandScheduler.Received(1)
                                  .ScheduleAsync("apps_ReverseCaseImportBatch",
                                                 Arg.Is<Dictionary<string, object>>(x => x.ContainsValue(batchId)))
                                  .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldPreventReverseWhenBatchNotFound()
        {
            var batch = JObject.FromObject(new
            {
                batchId = Fixture.Integer()
            });

            var r = await _subject.Reverse(batch);

            Assert.Equal("error", r.Result);
            Assert.Equal("batch-not-found", r.ErrorCode);
        }

        [Fact]
        public async Task ShouldPreventReverseWhenBatchStatusIndicatesOutputProduced()
        {
            var batchId = Fixture.Integer();
            var batch = JObject.FromObject(new {batchId});
            var batchStatus = new TableCode(EdeBatchStatus.OutputProduced, (short) TableTypes.EDEBatchStatus, Fixture.String()).In(Db);

            new EdeTransactionHeader
            {
                BatchId = batchId,
                BatchStatus = batchStatus
            }.In(Db);

            new ProcessRequest
            {
                BatchId = batchId,
                Context = ProcessRequestContexts.ElectronicDataExchange,
                RequestType = "EDE Resubmit Batch"
            }.In(Db);

            var r = await _subject.Reverse(batch);

            Assert.Equal("error", r.Result);
            Assert.Equal("batch-output-produced", r.ErrorCode);
        }

        [Fact]
        public async Task ShouldThrowArgumentNullExceptionWhenBatchIdNotProvided()
        {
            var batch = JObject.FromObject(new {batchId = string.Empty});

            await Assert.ThrowsAsync<ArgumentNullException>(async () => await _subject.Reverse(batch));
        }

        [Fact]
        public async Task ShouldThrowArgumentNullExceptionWhenBatchNotProvided()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await _subject.Reverse(null));
        }
    }
}