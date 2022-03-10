using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.VatReturns;
using InprotechKaizen.Model.Accounting.Tax;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Vat
{
    public class VatReturnStoreFacts : FactBase
    {
        public class AddMethod : FactBase
        {
            [Fact]
            public void AddsNewHmrcResponse()
            {
                var entityId = Fixture.Integer();
                var periodId = Fixture.String();
                var vrn = Fixture.String();
                var data = new {Id = "1", Data = "SomeData"};
                var f = new VatReturnStoreFixture(Db);
                f.Subject.Add(entityId, periodId, data, true, vrn);
                Assert.NotNull(Db.Set<VatReturn>().SingleOrDefault(_ => _.EntityId == entityId && _.PeriodId == periodId && _.IsSubmitted && _.Data.Contains("SomeData") && _.TaxNumber == vrn));
            }

            [Fact]
            public void AddsNewRowPerResponse()
            {
                var entityId = Fixture.Integer();
                var periodId = Fixture.String("1");
                var periodId2 = Fixture.String("2");
                var vrn = Fixture.String();
                var data = new {Id = "1", Data = "{Id = \"1\", Data = \"NewData\"}"};
                new VatReturn {Data = "{Id = \"1\", Data = \"SomeData\"}", EntityId = entityId, PeriodId = periodId, IsSubmitted = true, TaxNumber = vrn}.In(Db);
                new VatReturn {Data = "{Id = \"1\", Data = \"SomeData\"}", EntityId = entityId, PeriodId = periodId2, IsSubmitted = false, TaxNumber = vrn }.In(Db);
                var f = new VatReturnStoreFixture(Db);
                f.Subject.Add(entityId, periodId2, data, true, vrn);
                Assert.NotNull(Db.Set<VatReturn>().SingleOrDefault(_ => _.EntityId == entityId && _.PeriodId == periodId && _.Data.Contains("SomeData") && _.IsSubmitted && _.TaxNumber == vrn));
                Assert.NotNull(Db.Set<VatReturn>().SingleOrDefault(_ => _.EntityId == entityId && _.PeriodId == periodId2 && _.Data.Contains("SomeData") && !_.IsSubmitted && _.TaxNumber == vrn));
                Assert.NotNull(Db.Set<VatReturn>().SingleOrDefault(_ => _.EntityId == entityId && _.PeriodId == periodId2 && _.Data.Contains("NewData") && _.IsSubmitted && _.TaxNumber == vrn));
            }
        }
        
        [Fact]
        public void RetrievesVatReturnData()
        {
            var savedVatResponse = new VatReturn
            {
                Data = "{\"processingDate\":\"2019-03-08T05:36:09.499Z\",\"paymentIndicator\":\"DD\",\"formBundleNumber\":\"989029132190\",\"chargeRefNumber\":\"i5ITkeJ9trOGH0zs\"}",
                IsSubmitted = true,
                PeriodId = "18A2",
                EntityId = 1,
                TaxNumber = Fixture.String()
            }.In(Db);
            var f = new VatReturnStoreFixture(Db);
            var result = f.Subject.GetVatReturnResponse(savedVatResponse.TaxNumber, savedVatResponse.PeriodId);

            Assert.Equal(savedVatResponse.EntityId, result.EntityId);
            Assert.Equal(savedVatResponse.IsSubmitted, result.IsSubmitted);
            Assert.Equal(savedVatResponse.PeriodId, result.PeriodId);
            Assert.Equal(savedVatResponse.Data, result.Data);
            Assert.Equal(savedVatResponse.TaxNumber, result.TaxNumber);
        }

        [Fact]
        public void RetrievesCorrectLogData()
        {
            new VatReturn
            {
                Data = "{\"processingDate\":\"2019-03-08T05:36:09.499Z\",\"paymentIndicator\":\"DD\",\"formBundleNumber\":\"989029132190\",\"chargeRefNumber\":\"i5ITkeJ9trOGH0zs\"}",
                IsSubmitted = true,
                PeriodId = "18A2",
                EntityId = 1,
                TaxNumber = "1"
            }.In(Db);
            var error1 = new VatReturn
            {
                Data = Fixture.String(),
                IsSubmitted = false,
                PeriodId = "18A1",
                EntityId = 2,
                TaxNumber = "2"
            }.In(Db);
            var error2 = new VatReturn
            {
                Data = Fixture.String(),
                IsSubmitted = false,
                PeriodId = "18A1",
                EntityId = 2,
                TaxNumber = "2"
            }.In(Db);
            var f = new VatReturnStoreFixture(Db);
            var result = f.Subject.GetLogData("2", "18A1").ToArray();

            Assert.Contains(result, v => v.Data == error1.Data);
            Assert.Contains(result, v => v.Data == error2.Data);
            Assert.Equal(2, result.Length);
        }

        public class HasAccessLogs : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void CorrectlyChecksIfThereAreSuccessfulSubmits(bool succesfullySubmitted)
            {
                new VatReturn
                {
                    Data = "{\"processingDate\":\"2019-03-08T05:36:09.499Z\",\"paymentIndicator\":\"DD\",\"formBundleNumber\":\"989029132190\",\"chargeRefNumber\":\"i5ITkeJ9trOGH0zs\"}",
                    IsSubmitted = succesfullySubmitted,
                    PeriodId = "18A1",
                    EntityId = 1,
                    TaxNumber = "1"
                }.In(Db);
                new VatReturn
                {
                    Data = Fixture.String(),
                    IsSubmitted = false,
                    PeriodId = "18A1",
                    EntityId = 1,
                    TaxNumber = "1"
                }.In(Db);
                new VatReturn
                {
                    Data = Fixture.String(),
                    IsSubmitted = false,
                    PeriodId = "18A1",
                    EntityId = 1,
                    TaxNumber = "1"
                }.In(Db);
                var f = new VatReturnStoreFixture(Db);
                var result = f.Subject.HasLogErrors("1", "18A1");

                Assert.False(result == succesfullySubmitted);
            }

            [Fact]
            public void ReturnFalseWhenNoDataStored()
            {
                var f = new VatReturnStoreFixture(Db);
                var result = f.Subject.HasLogErrors("1", "18A1");
                Assert.False(result);
            }
        }

        public class VatReturnStoreFixture : IFixture<VatReturnStore>
        {
            public VatReturnStoreFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Subject = new VatReturnStore(DbContext);
            }
            public InMemoryDbContext DbContext { get; set; }
            public VatReturnStore Subject { get; }
        }
    }
}
