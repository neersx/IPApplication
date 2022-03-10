using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class VersionableContentResolver : IVersionableContentResolver
    {
        public Task<string> Resolve(DataDownload dataDownload)
        {
            if (!string.IsNullOrEmpty(dataDownload.AdditionalDetails))
                return Value(dataDownload.AdditionalDetails);

            dynamic validationResult = dataDownload.IsPatentsDataValidation()
                                        ? (dynamic)dataDownload.GetExtendedDetails<ValidationResult>()
                                            : (dynamic)dataDownload.GetExtendedDetails<TrademarkDataValidationResult>();

            return Value(JsonConvert.SerializeObject(validationResult, Formatting.None));
        }

        static Task<string> Value(string val)
        {
            return Task.FromResult(val);
        }
    }
}