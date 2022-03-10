using System;
using System.Linq;

namespace Inprotech.Infrastructure.StorageService
{
    public interface IValidateHttpOrHttpsString
    {
        bool Validate(string value);
    }

    public class ValidateHttpOrHttpsString : IValidateHttpOrHttpsString
    {
        static readonly string[] ValidSchemes = { Uri.UriSchemeHttps, Uri.UriSchemeHttp, Uri.UriSchemeFtp, "iwl" };

        public bool Validate(string value)
        {
            bool result = Uri.TryCreate(value, UriKind.Absolute, out var uri)
                          && ValidSchemes.Contains(uri.Scheme);
            return result;
        }
    }
}
