using System;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class InnographyRequestMessageFacts
    {
        const string Username = "obiwan";
        const string Secret = "74f43da743aa47c3a90a9c5ef493bc8d";
        const string Version = "1.2.3";

        readonly Func<DateTime> _now = () => DateTime.Parse("Thu, 12 Jan 2017 16:17:39 GMT");

        readonly Uri _api = new Uri("https://_api.innography.com/private-pair/account");

        [Theory]
        [InlineData("Null", "hmac-sha1", "33K74OzzqvrSXsQ5RWw91EH4rJs=")]
        [InlineData("Default", "hmac-sha1", "33K74OzzqvrSXsQ5RWw91EH4rJs=")]
        [InlineData("Null", "hmac-sha256", "JAegT6mMqTILF6/X+KlvKbCl9QCwy3NQQlUw4eNVW9Y=")]
        public async Task EmitsSameHeaderNoData(string type, string cryptoAlgorithm, string signature)
        {
            /*
            Example request with no data and hmac-sha1 crypto algorithm($body = []).

            curl -X POST http://api.innography.com/private-pair/account \
            -H 'Content-Type: application/json' \
            -H 'Date: Thu, 12 Jan 2017 16:17:39 GMT' \
            -H 'Content-MD5: 11FxOYiYfpMxmANj4kGJzg==' \
            -H 'Accept: application/vnd.innography+json; version=1.2.3' \
            -H 'Authorization: hmac username="obiwan", algorithm="hmac-sha1", headers="Date Content-MD5", signature="33K74OzzqvrSXsQ5RWw91EH4rJs="'

            */

            /*
            Example request with no data and hmac-sha256 crypto algorithm($body = []).

            curl -X POST http://api.innography.com/private-pair/account \
            -H 'Content-Type: application/json' \
            -H 'Date: Thu, 12 Jan 2017 16:17:39 GMT' \
            -H 'Content-MD5: 11FxOYiYfpMxmANj4kGJzg==' \
            -H 'Accept: application/vnd.innography+json; version=1.2.3' \
            -H 'Authorization: hmac username="obiwan", algorithm="hmac-sha256", headers="Date Content-MD5", signature="JAegT6mMqTILF6/X+KlvKbCl9QCwy3NQQlUw4eNVW9Y="'

            */

            var subject = new InnographyRequestMessage(_now);

            var data = type == "Default"
                ? new string[0]
                : null;

            var request = await subject.Create(HttpMethod.Post, _api, Username, Secret, Version, cryptoAlgorithm, data);

            var header = request.ToString();

            Assert.Contains($"Accept: application/vnd.innography+json; version={Version}", header);

            Assert.Contains("Date: Thu, 12 Jan 2017 16:17:39 GMT", header);

            Assert.Contains($"Authorization: hmac username=\"obiwan\", algorithm=\"{cryptoAlgorithm}\", headers=\"Date Content-MD5\", signature=\"{signature}\"", header);

            Assert.Contains("Content-MD5: 11FxOYiYfpMxmANj4kGJzg==", header);
        }

        [Fact]
        public async Task EmitsSameHeaderWithSampleData()
        {
            /*
            Example request with data ($body = ["data" => "sample"]).
            curl -X POST http://api.innography.com/private-pair/account \
            -H 'Content-Type: application/json' \
            -H 'Date: Thu, 12 Jan 2017 16:17:39 GMT' \
            -H 'Content-MD5: kumW7r4Mo58KzBliGOerdA==' \
            -H 'Accept: application/vnd.innography+json; version=1.2.3' \
            -H 'Authorization: hmac username="obiwan", algorithm="hmac-sha1", headers="Date Content-MD5", signature="2zS0VJJ6YipaXDU3IcerHJZdpP8="' \
            -d '{"data":"sample"}'
             */

            var subject = new InnographyRequestMessage(_now);

            var data = new
            {
                data = "sample"
            };

            var request = await subject.Create(HttpMethod.Post, _api, Username, Secret, Version, CryptoAlgorithm.Sha1, data);

            var header = request.ToString();

            Assert.Contains($"Accept: application/vnd.innography+json; version={Version}", header);

            Assert.Contains("Date: Thu, 12 Jan 2017 16:17:39 GMT", header);

            Assert.Contains("Authorization: hmac username=\"obiwan\", algorithm=\"hmac-sha1\", headers=\"Date Content-MD5\", signature=\"2zS0VJJ6YipaXDU3IcerHJZdpP8=\"", header);

            Assert.Contains("Content-MD5: kumW7r4Mo58KzBliGOerdA==", header);
        }
    }
}