using Inprotech.Web.ExchangeIntegration;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Names;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.ExchangeIntegration
{
    public class RequestItemModelFacts
    {
        [Theory]
        [InlineData((short)0)]
        [InlineData((short)1)]
        [InlineData((short)2)]
        [InlineData((short)3)]
        public void ReturnsFormattedStatus(short code)
        {
            var status = KnownRequestStatus.GetStatus(code);
            var request = new
            {
                Item = new ExchangeRequestQueueItem
                {
                    StatusId = code,
                    RequestTypeId = Fixture.Short()
                }
            };

            var result = new RequestQueueItemModel().Get(request.Item, Fixture.String(), Fixture.String());
            Assert.Equal(code, result.StatusId);
            Assert.Equal(status, result.Status);
        }

        [Theory]
        [InlineData((short)0)]
        [InlineData((short)1)]
        [InlineData((short)2)]
        [InlineData((short)3)]
        [InlineData((short)4)]
        public void ReturnsFormattedRequestType(short code)
        {
            var requestType = KnownRequestType.GetType(code);
            var request = new
            {
                Item = new ExchangeRequestQueueItem
                {
                    StatusId = Fixture.Short(),
                    RequestTypeId = code
                }
            };

            var result = new RequestQueueItemModel().Get(request.Item, Fixture.String(), Fixture.String());
            Assert.Equal(code, result.RequestTypeId);
            Assert.Equal(requestType, result.TypeOfRequest);
        }

        [Fact]
        public void LeavesOtherDetailsIntact()
        {
            var requestDate = Fixture.PastDate();
            var failedMessage = Fixture.String("Error");
            var eventId = Fixture.Integer();
            var eventDescription = Fixture.String("Event");
            var request = new
            {
                Item = new ExchangeRequestQueueItem
                {
                    DateCreated = requestDate,
                    ErrorMessage = failedMessage,
                    EventId = eventId
                }
            };

            var result = new RequestQueueItemModel().Get(request.Item, eventDescription, Fixture.String());
            Assert.Equal(requestDate, result.RequestDate);
            Assert.Equal(failedMessage, result.FailedMessage);
            Assert.Equal(eventId, result.EventId);
            Assert.Equal(eventDescription, result.EventDescription);
        }

        [Fact]
        public void ReturnsAdHocReference()
        {
            var adHocReference = Fixture.String();
            var request = new
            {
                Item = new ExchangeRequestQueueItem
                {
                    StaffId = Fixture.Integer(),
                    Reference = adHocReference
                }
            };

            var result = new RequestQueueItemModel().Get(request.Item, Fixture.String(), Fixture.String());
            Assert.Equal(adHocReference, result.Reference);
        }

        [Fact]
        public void ReturnsCaseIrnAsReference()
        {
            var request = new
            {
                Item = new ExchangeRequestQueueItem
                {
                    StaffId = Fixture.Integer(),
                    Case = new Case { Irn = "CaseRef" },
                    Name = new Name { FirstName = "Redundant" },
                    Reference = Fixture.String()
                }
            };

            var result = new RequestQueueItemModel().Get(request.Item, Fixture.String(), Fixture.String());
            Assert.Equal("CaseRef", result.Reference);
        }

        [Fact]
        public void ReturnsFormattedNameAsReference()
        {
            var name = new Name { FirstName = "a", LastName = "b" };
            var formattedName = name.Formatted();
            var request = new
            {
                Item = new ExchangeRequestQueueItem
                {
                    StaffId = Fixture.Integer(),
                    Name = new Name { FirstName = "a", LastName = "b" },
                    Reference = Fixture.String()
                }
            };

            var result = new RequestQueueItemModel().Get(request.Item, Fixture.String(), Fixture.String());
            Assert.Equal(formattedName, result.Reference);
        }

        [Fact]
        public void ReturnsFormattedStaffName()
        {
            var staffName = new Name { FirstName = "a", LastName = "b" };
            var formattedName = staffName.Formatted();
            var request = new
            {
                Item = new ExchangeRequestQueueItem
                {
                    StaffId = Fixture.Integer(),
                    StaffName = new Name { FirstName = "a", LastName = "b" }
                }
            };

            var result = new RequestQueueItemModel().Get(request.Item, Fixture.String(), Fixture.String());
            Assert.Equal(formattedName, result.Staff);
        }
    }
}