using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class NumberForEventResolverFacts : FactBase
    {
        readonly int _caseId = Fixture.Integer();

        (string number, string numberTypeCode, int? relatedEventNo, int? dataItemId) CreateNumberTypeAndNumberPair(Event @event = null, short displayPriority = 1, bool isCurrent = true, bool isIpOfficeNumber = true)
        {
            var numberType = new NumberTypeBuilder
            {
                IssuedByIpOffice = isIpOfficeNumber,
                RelatedEventNo = (@event ?? new EventBuilder().Build().In(Db)).Id,
                DisplayPriority = displayPriority
            }.Build().In(Db);

            var number = new OfficialNumberBuilder
            {
                CaseId = _caseId,
                IsCurrent = isCurrent ? 1 : 0,
                NumberType = numberType,
                OfficialNo = Fixture.String()
            }.Build().In(Db);

            return (number.Number, numberType.NumberTypeCode, numberType.RelatedEventId, numberType.DocItemId);
        }

        [Fact]
        public void ShouldNotReturnNonCurrentNumbers()
        {
            CreateNumberTypeAndNumberPair(isCurrent: false);

            var current = CreateNumberTypeAndNumberPair();

            var subject = new NumberForEventResolver(Db);

            var result = subject.Resolve(_caseId).ToArray();

            Assert.Single(result);

            Assert.Equal(current.relatedEventNo, result.Single().EventNo);
            Assert.Equal(current.numberTypeCode, result.Single().NumberType);
            Assert.Equal(current.number, result.Single().OfficialNumber);
        }

        [Fact]
        public void ShouldNotReturnNonIpOfficeNumbers()
        {
            CreateNumberTypeAndNumberPair(isIpOfficeNumber: false);

            var current = CreateNumberTypeAndNumberPair();

            var subject = new NumberForEventResolver(Db);

            var result = subject.Resolve(_caseId).ToArray();

            Assert.Single(result);

            Assert.Equal(current.relatedEventNo, result.Single().EventNo);
            Assert.Equal(current.numberTypeCode, result.Single().NumberType);
            Assert.Equal(current.number, result.Single().OfficialNumber);
        }

        [Fact]
        public void ShouldReturnCurrentNumbersFromIpOffices()
        {
            var pair1 = CreateNumberTypeAndNumberPair();
            var pair2 = CreateNumberTypeAndNumberPair();

            var subject = new NumberForEventResolver(Db);

            var result = subject.Resolve(_caseId).ToArray();

            Assert.Equal(2, result.Length);

            Assert.Equal(pair1.relatedEventNo, result.First().EventNo);
            Assert.Equal(pair1.numberTypeCode, result.First().NumberType);
            Assert.Equal(pair1.number, result.First().OfficialNumber);
            Assert.Equal(pair1.dataItemId, result.First().DataItemId);

            Assert.Equal(pair2.relatedEventNo, result.Last().EventNo);
            Assert.Equal(pair2.numberTypeCode, result.Last().NumberType);
            Assert.Equal(pair2.number, result.Last().OfficialNumber);
            Assert.Equal(pair2.dataItemId, result.Last().DataItemId);
        }

        [Fact]
        public void ShouldReturnNumberHavingLowestDisplayPriorityAcrossAllNumberTypesSharingSameEvent()
        {
            var @event = new EventBuilder().Build().In(Db);

            var pair1 = CreateNumberTypeAndNumberPair(@event, 20);
            var pair2 = CreateNumberTypeAndNumberPair(@event, 10);
            var pair3 = CreateNumberTypeAndNumberPair(@event, 30);

            var subject = new NumberForEventResolver(Db);

            var result = subject.Resolve(_caseId).ToArray();

            Assert.Single(result);

            Assert.Equal(pair2.relatedEventNo, result.Single().EventNo);
            Assert.Equal(pair2.numberTypeCode, result.Single().NumberType);
            Assert.Equal(pair2.number, result.Single().OfficialNumber);
            Assert.Equal(pair2.dataItemId, result.Single().DataItemId);
        }
    }
}