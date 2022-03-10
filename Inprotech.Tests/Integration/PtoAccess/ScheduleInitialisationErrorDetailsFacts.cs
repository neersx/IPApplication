using Inprotech.Integration.Diagnostics.PtoAccess;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class ScheduleInitialisationErrorDetailsFacts
    {
        [Fact]
        public void ExtractRelevantInformation()
        {
            var json = Tools.ReadFromEmbededResource(@"Inprotech.Tests.Integration.PtoAccess.ScheduleError.txt");

            var a = new ScheduleInitialisationErrorDetails
            {
                RawError = json
            };

            Assert.Equal(JArray.Parse(json).ToString(), a.Error.ToString());
            Assert.Equal("Unable to extract customer numbers", a.Message);
            Assert.Equal("UsptoIntegration\\PAIR - Toffenetti - Daily Correspondence Download\\c47ccd9d-893c-44f8-92ac-d6cfd7701a5f\\14010\\Logs\\6a21ff3f-7b8a-4a8d-996f-f1ff5fec3c8e.data.txt", a.AdditionalInfoPath);
            Assert.Equal("Inprotech.Integration.UsptoDataExtraction.Activities.DocumentList", a.Activity);
        }

        [Fact]
        public void ShouldNotErrorWhileRetrievingErrorInfo()
        {
            var a = new ScheduleInitialisationErrorDetails
            {
                RawError = "{}"
            };

            Assert.Null(a.Message);
            Assert.Null(a.AdditionalInfoPath);
            Assert.Null(a.Activity);
        }
    }
}