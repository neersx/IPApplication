using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipStatusEvaluatorFacts : FactBase
    {
        [Fact]
        public async Task ThrowsExceptionIfNoRecordsFound()
        {
            var f = new WipStatusEvaluatorFixture(Db);
            await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.GetWipStatus(10, 10));
        }

        [Theory]
        [InlineData(0)]
        [InlineData(100)]
        public async Task ReturnsCorrectBilledStatusIfNoWipCreated(decimal value)
        {
            new Diary {EntryNo = 10, EmployeeNo = 100, WipEntityId = 99, TransactionId = 9, TimeValue = value}.In(Db);
            var f = new WipStatusEvaluatorFixture(Db);

            var result = await f.Subject.GetWipStatus(10, 100);
            Assert.Equal(value > 0 ? WipStatusEnum.Billed : WipStatusEnum.Editable, result);
        }

        [Fact]
        public async Task ReturnsAdjustedStatusIfAllWipsAreDiscount()
        {
            new Diary {EntryNo = 10, EmployeeNo = 100, WipEntityId = 99, TransactionId = 9}.In(Db);
            new WorkInProgress {EntityId = 99, TransactionId = 9, IsDiscount = 1}.In(Db);
            var f = new WipStatusEvaluatorFixture(Db);

            var result = await f.Subject.GetWipStatus(10, 100);
            Assert.Equal(WipStatusEnum.Adjusted, result);
        }

        [Fact]
        public async Task ReturnsAdjustedStatus()
        {
            new Diary {EntryNo = 10, EmployeeNo = 100, WipEntityId = 99, TransactionId = 9, TimeValue = 99}.In(Db);
            new WorkInProgress {EntityId = 99, TransactionId = 9, IsDiscount = 0, Balance = 88}.In(Db);
            var f = new WipStatusEvaluatorFixture(Db);

            var result = await f.Subject.GetWipStatus(10, 100);
            Assert.Equal(WipStatusEnum.Adjusted, result);
        }

        [Fact]
        public async Task ReturnsBilledIfWorkHistoryPresent()
        {
            new Diary {EntryNo = 10, EmployeeNo = 100, WipEntityId = 99, TransactionId = 9}.In(Db);
            new WorkInProgress {EntityId = 99, TransactionId = 9, IsDiscount = 0}.In(Db);
            new WorkHistory {EntityId = 99, TransactionId = 9, TransactionType = TransactionType.Bill}.In(Db);
            var f = new WipStatusEvaluatorFixture(Db);

            var result = await f.Subject.GetWipStatus(10, 100);
            Assert.Equal(WipStatusEnum.Billed, result);
        }
    }

    public class WipStatusEvaluatorFixture : IFixture<WipStatusEvaluator>
    {
        public WipStatusEvaluatorFixture(InMemoryDbContext dbContext)
        {
            Subject = new WipStatusEvaluator(dbContext);
        }

        public WipStatusEvaluator Subject { get; }
    }
}