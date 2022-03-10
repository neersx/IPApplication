using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.ExchangeIntegration;

namespace Inprotech.Web.ExchangeIntegration
{
    public interface IRequestQueueItemModel
    {
        RequestQueueItem Get(ExchangeRequestQueueItem requestQueueItem, string eventDescription, string mailbox);
    }

    public class RequestQueueItemModel : IRequestQueueItemModel
    {
        public RequestQueueItem Get(ExchangeRequestQueueItem requestQueueItem, string eventDescription, string mailbox)
        {
            return new RequestQueueItem
            {
                Id = requestQueueItem.Id,
                Staff = requestQueueItem.StaffName?.Formatted(),
                Reference = requestQueueItem.Case?.Irn ?? requestQueueItem.Name?.Formatted() ?? requestQueueItem.Reference,
                RequestDate = requestQueueItem.DateCreated,
                Status = requestQueueItem.RequestStatus(),
                TypeOfRequest = requestQueueItem.RequestType(),
                FailedMessage = requestQueueItem.ErrorMessage,
                StatusId = requestQueueItem.StatusId,
                RequestTypeId = requestQueueItem.RequestTypeId,
                EventId = requestQueueItem.EventId,
                EventDescription = (ExchangeRequestType)requestQueueItem.RequestTypeId == ExchangeRequestType.SaveDraftEmail ? requestQueueItem.Subject : eventDescription,
                Mailbox = mailbox,
                RecipientEmail = (ExchangeRequestType)requestQueueItem.RequestTypeId == ExchangeRequestType.SaveDraftEmail && !string.IsNullOrWhiteSpace(requestQueueItem.Recipients) ? string.Join("; ", requestQueueItem.Recipients.Split(';')) : string.Empty
            };
        }
    }
}
