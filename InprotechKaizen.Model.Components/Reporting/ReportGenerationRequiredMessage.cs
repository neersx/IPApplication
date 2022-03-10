using Inprotech.Contracts.Messages;

namespace InprotechKaizen.Model.Components.Reporting
{
    public class ReportGenerationRequiredMessage : Message
    {
        public ReportGenerationRequiredMessage(ReportRequest request)
        {
            ReportRequestModel = request;
        }

        public ReportRequest ReportRequestModel { get; set; }
    }
}