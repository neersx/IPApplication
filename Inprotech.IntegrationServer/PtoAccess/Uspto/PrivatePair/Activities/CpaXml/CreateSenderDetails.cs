using CPAXML;
using Inprotech.Integration.Innography.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml
{
    public interface ICreateSenderDetails
    {
        SenderDetails For(string sender, RequestType requestType);
    }

    public class CreateSenderDetails : ICreateSenderDetails
    {
        public SenderDetails For(string sender, RequestType requestType)
        {
            return new SenderDetails(sender)
            {
                SenderRequestFixType = requestType,
                SenderFilename = KnownFileNames.CpaXml,
                SenderSoftware = new SenderSoftware { SenderSofwareName = "Inprotech" },
                SenderRequestIdentifier = KnownFileNames.CpaXml
            };
        }
    }
}
