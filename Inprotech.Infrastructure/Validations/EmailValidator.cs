using System.Text.RegularExpressions;

namespace Inprotech.Infrastructure.Validations
{
    public interface IEmailValidator
    {
        bool IsValid(string emailId);
    }

    public class EmailValidator : IEmailValidator
    {
        readonly ISiteControlReader _siteControlReader;

        public EmailValidator(ISiteControlReader siteControlReader)
        {
            _siteControlReader = siteControlReader;
        }

        public bool IsValid(string emailId)
        {
            var validPattern = _siteControlReader.Read<string>(SiteControls.ValidPatternForEmailAddresses);
            if (string.IsNullOrEmpty(validPattern)) return true;
            var expression = new Regex(validPattern);
            var match = expression.Match(Regex.Replace(emailId, @"\s", string.Empty));
            return match.Success;
        }
    }
}