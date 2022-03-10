using System.Collections.Generic;
using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyTrademarksValidationRequestMapping
    {
        TrademarkDataValidationRequest[] MapRequests(IEnumerable<TrademarkDataResponse> innographyIdsResults, IEnumerable<TrademarkDataRequest> requests);
    }

    public class InnographyTrademarksValidationRequestMapping : IInnographyTrademarksValidationRequestMapping
    {
        public TrademarkDataValidationRequest[] MapRequests(IEnumerable<TrademarkDataResponse> innographyIdsResults, IEnumerable<TrademarkDataRequest> requests)
        {
            return (from responseResult in innographyIdsResults.Where(_ => !string.IsNullOrWhiteSpace(_.IpId))
                    join request in requests on responseResult.ClientIndex equals request.ClientIndex
                    select new TrademarkDataValidationRequest
                    {
                        IpId = responseResult.IpId,
                        ClientIndex = request.ClientIndex,
                        ApplicationDate = request.ApplicationDate,
                        ApplicationNumber = request.ApplicationNumber,
                        RegistrationDate = request.RegistrationDate,
                        RegistrationNumber = request.RegistrationNumber,
                        CountryCode = request.CountryCode,
                        PublicationDate = request.PublicationDate,
                        PublicationNumber = request.PublicationNumber,
                        PriorityDate = request.PriorityDate,
                        PriorityNumber = request.PriorityNumber,
                        PriorityCountry = request.PriorityCountry,
                        ExpirationDate = request.ExpirationDate,
                        TerminationDate = request.TerminationDate
                    }).ToArray();
        }
    }
}
