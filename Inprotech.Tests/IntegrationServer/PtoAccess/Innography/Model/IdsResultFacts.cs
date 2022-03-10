using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Model
{
    public class IdsResultFacts
    {
        [Fact]
        public void DeserialisesFullResponse()
        {
            const string sample = "{\"ipid\":\"I-000033726180\",\"message\":\"Matched - validation issues\",\"validation\":[\"Check application date\",\"Check grant date\"],\"client_index\":\"-4\",\"public_data\":{\"application_number\":\"AU19900065827\",\"application_date\":\"1989-11-14\",\"publication_number\":\"AU635979B2\",\"publication_date\":\"1993-04-08\",\"grant_number\":\"AU635979B2\",\"grant_date\":\"1993-04-08\",\"type_code\":null,\"country_code\":\"AU\",\"country_name\":\"Australia\",\"title\":\"BOILING WATER UNITS\",\"inventors\":\"Raymond, Dennis Massey|Christopher, Roy Martin|Stephen, James Chaplin\"},\"confidence\":\"low\"}";

            var r = JsonConvert.DeserializeObject<IpIdResult>(sample);

            Assert.Equal("I-000033726180", r.IpId);
            Assert.Equal("Matched - validation issues", r.Message);
            Assert.Equal(new[]
            {
                "Check application date",
                "Check grant date"
            }, r.Validation);
            Assert.Equal("-4", r.ClientIndex);
            Assert.Equal("low", r.Confidence);
            Assert.Equal("AU19900065827", r.PublicData.ApplicationNumber);
            Assert.Equal("1989-11-14", r.PublicData.ApplicationDate);
            Assert.Equal("AU635979B2", r.PublicData.PublicationNumber);
            Assert.Equal("1993-04-08", r.PublicData.PublicationDate);
            Assert.Equal("AU635979B2", r.PublicData.GrantNumber);
            Assert.Equal("1993-04-08", r.PublicData.GrantDate);
            Assert.Equal("AU", r.PublicData.CountryCode);
            Assert.Equal("Australia", r.PublicData.CountryName);
            Assert.Equal("BOILING WATER UNITS", r.PublicData.Title);
            Assert.Null(r.PublicData.TypeCode);
            Assert.Equal("Raymond, Dennis Massey|Christopher, Roy Martin|Stephen, James Chaplin", r.PublicData.Inventors);
        }

        [Fact]
        public void DeserialisesNonMatchResponse()
        {
            const string sample = "{\"ipid\":0,\"client_index\":\"6\",\"message\":\"Not Matched\",\"validation\":[]}";

            var r = JsonConvert.DeserializeObject<IpIdResult>(sample);

            Assert.Equal("0", r.IpId);
            Assert.Equal("Not Matched", r.Message);
            Assert.Equal(new string[0], r.Validation);
            Assert.Equal("6", r.ClientIndex);
            Assert.Null(r.PublicData);
        }
    }
}