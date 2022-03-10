using System;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type
{
    public interface IBillDeliveryService
    {
        Task Deliver(int userIdentityId, string culture, Guid contextId, params BillGenerationRequest[] requests);

        Task EnsureValidSettings();
    }
}