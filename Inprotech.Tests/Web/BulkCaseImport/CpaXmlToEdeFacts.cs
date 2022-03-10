using System.Threading;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model.Ede;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class CpaXmlToEdeFacts
    {
        public class CpaXmlToEdeFixture : IFixture<CpaXmlToEde>
        {
            public CpaXmlToEdeFixture(InMemoryDbContext db)
            {
                SqlXmlBulkLoad = Substitute.For<ISqlXmlBulkLoad>();

                BulkLoadProcessing = Substitute.For<IBulkLoadProcessing>();

                Subject = new CpaXmlToEde(SqlXmlBulkLoad, BulkLoadProcessing, db);
            }

            public IBulkLoadProcessing BulkLoadProcessing { get; }

            public ISqlXmlBulkLoad SqlXmlBulkLoad { get; }

            public CpaXmlToEde Subject { get; }
        }

        public class PrepareForEdeMethod : FactBase
        {
            [Fact]
            public void CheckConcurrencyScenarioForBulkImport()
            {
                var firstRequestDispatched = new ManualResetEvent(false);
                var block = new ManualResetEvent(false);

                var firstRequest = new CpaXmlToEdeFixture(Db);

                firstRequest.BulkLoadProcessing.CurrentDbContextUser()
                            .ReturnsForAnyArgs(
                                               c =>
                                               {
                                                   firstRequestDispatched.Set();
                                                   block.WaitOne();

                                                   return "current user";
                                               });

                Task.Run(() => firstRequest.Subject.PrepareEdeBatch("something", out _));
                firstRequestDispatched.WaitOne();

                var secondRequest = new CpaXmlToEdeFixture(Db);
                var returnValue = secondRequest.Subject.PrepareEdeBatch("SomeString", out _);

                block.Set();

                Assert.False(returnValue);
                secondRequest.SqlXmlBulkLoad.DidNotReceiveWithAnyArgs().TryExecute(null, null, out _);
            }

            [Fact]
            public void LoadsDataIntoEdeTables()
            {
                var f = new CpaXmlToEdeFixture(Db);

                f.SqlXmlBulkLoad.TryExecute(Arg.Any<string>(), Arg.Any<string>(), out _)
                 .ReturnsForAnyArgs(true);

                const int batchNumber = 9999;

                f.BulkLoadProcessing.AcquireBatchNumber().Returns(batchNumber);
                f.BulkLoadProcessing.CurrentDbContextUser().Returns("current user");

                var returnValue = f.Subject.PrepareEdeBatch("SomeString", out _);

                Assert.True(returnValue);

                f.SqlXmlBulkLoad.Received(1).TryExecute(Arg.Any<string>(), Arg.Any<string>(), out _);

                f.BulkLoadProcessing.Received(1).ClearCorruptBatch("current user");

                f.BulkLoadProcessing.Received(1).AcquireBatchNumber();

                f.BulkLoadProcessing.Received(1).ValidateBatchHeader(batchNumber);
            }
        }

        public class SubmitMethod : FactBase
        {
            [Fact]
            public void RejectsIfBatchDataIsNotFound()
            {
                var f = new CpaXmlToEdeFixture(Db);

                var exception = Record.Exception(
                                                 () => { f.Subject.Submit(999); });

                f.BulkLoadProcessing.DidNotReceive().SubmitToEde(999);

                Assert.NotNull(exception);
            }

            [Fact]
            public void SubmitsToEde()
            {
                new EdeSenderDetails
                {
                    TransactionHeader = new EdeTransactionHeader {BatchId = 999}.In(Db),
                    SenderRequestIdentifier = "ABCDE",
                    SenderRequestType = "Data Input",
                    Sender = "MYAC"
                }.In(Db);

                var f = new CpaXmlToEdeFixture(Db);

                var r = f.Subject.Submit(999);

                Assert.Equal("ABCDE", r);

                f.BulkLoadProcessing.Received(1).SubmitToEde(999);
            }
        }
    }
}