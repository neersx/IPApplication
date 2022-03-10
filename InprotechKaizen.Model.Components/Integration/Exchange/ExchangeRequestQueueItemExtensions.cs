using System;
using InprotechKaizen.Model.ExchangeIntegration;

namespace InprotechKaizen.Model.Components.Integration.Exchange
{
    public static class ExchangeRequestQueueItemExtensions
    {
        public static string RequestStatus(this ExchangeRequestQueueItem request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return KnownRequestStatus.GetStatus(request.StatusId);
        }

        public static string RequestType(this ExchangeRequestQueueItem request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return KnownRequestType.GetType(request.RequestTypeId);
        }
    }
}
