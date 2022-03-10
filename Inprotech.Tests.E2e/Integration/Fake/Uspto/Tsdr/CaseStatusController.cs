using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using System.Web.Http;

namespace Inprotech.Tests.E2e.Integration.Fake.Uspto.Tsdr
{
    public class CaseStatusController : ApiController
    {
        readonly string[] _availableFiles =
        {
            "77206698", "79039306", "86516598"
        };

        [HttpGet]
        [Route("integration/uspto/tsdr/ts/cd/casedocs/sn{number}/zip-bundle-download")]
        public HttpResponseMessage SerialNumber(string number)
        {
            if (_availableFiles.Contains(number))
                return ResponseHelper.ResponseAsStream(string.Format("uspto/tsdr/{0}.zip", number));

            var stream = GetZipMemoryStream(number);

            return ResponseHelper.RespondWithStream(stream, string.Format("{0}.zip", number), ".zip");
        }

        [HttpGet]
        [Route("integration/uspto/tsdr/ts/cd/casedocs/rn{number}/zip-bundle-download")]
        public HttpResponseMessage RegistrationNumber(string number)
        {
            var returnSerialNumber = new Random().Next(1, 99999999).ToString().PadLeft(8, '0');

            var stream = GetZipMemoryStream(returnSerialNumber);

            return ResponseHelper.RespondWithStream(stream, string.Format("{0}.zip", returnSerialNumber), ".zip");
        }

        static MemoryStream GetZipMemoryStream(string returnSerialNumber)
        {
            var stream = new MemoryStream();
            var zipFile = new ZipArchive(stream, ZipArchiveMode.Create, true);

            zipFile.CreateEntryFromFile(
                ResponseHelper.GetAbsolutePath("uspto/tsdr/ziptemplate/status_st96.xml"),
                string.Format("{0}_status_st96.xml", returnSerialNumber));
            zipFile.CreateEntryFromFile(ResponseHelper.GetAbsolutePath("uspto/tsdr/ziptemplate/markImage.png"),
                string.Format("{0}.png", returnSerialNumber));
            zipFile.CreateEntryFromFile(
                ResponseHelper.GetAbsolutePath("uspto/tsdr/ziptemplate/markThumbnailImage.png"),
                "markThumbnailImage.png");

            zipFile.Dispose(); // dispose adds the eof marker

            return stream;
        }
    }
}