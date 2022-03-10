using System.Collections.Generic;
using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyPatentsValidationRequestMapping
    {
        PatentDataValidationRequest[] MapRequests(IEnumerable<IpIdResult> innographyIdsResults, IEnumerable<PatentDataMatchingRequest> requests);
    }

    public class InnographyPatentsValidationRequestMapping : IInnographyPatentsValidationRequestMapping
    {
        public PatentDataValidationRequest[] MapRequests(IEnumerable<IpIdResult> innographyIdsResults, IEnumerable<PatentDataMatchingRequest> requests)
        {
            return (from responseResult in innographyIdsResults.Where(_ => !string.IsNullOrWhiteSpace(_.IpId))
                    join request in requests on responseResult.ClientIndex equals request.ClientIndex
                    select new PatentDataValidationRequest
                    {
                        IpId = responseResult.IpId,
                        ClientIndex = request.ClientIndex,
                        ApplicationDate = request.ApplicationDate,
                        ApplicationNumber = request.ApplicationNumber,
                        CountryCode = request.CountryCode,
                        CountryName = request.CountryName,
                        GrantDate = request.GrantDate,
                        GrantNumber = request.GrantNumber,
                        Inventors = request.Inventors,
                        PublicationDate = request.PublicationDate,
                        PublicationNumber = request.PublicationNumber,
                        Title = request.Title,
                        TypeCode = request.TypeCode,
                        GrantPublicationDate = request.GrantPublicationDate,
                        PctDate = request.PctDate,
                        PctNumber = request.PctNumber,
                        PctCountry = request.PctCountry,
                        PriorityDate = request.ParentDate,
                        PriorityNumber = request.ParentNumber,
                        PriorityCountry = request.ParentCountry
                    }).ToArray();
        }
    }
}
