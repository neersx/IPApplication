using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Security
{
    public abstract class Response
    {
        protected Response(string failReasonCode = null)
        {
            FailReasonCode = failReasonCode;
        }

        public string FailReasonCode { get; set; }

        public bool Accepted => string.IsNullOrWhiteSpace(FailReasonCode);

        public override string ToString()
        {
            return FailReasonCode;
        }
    }

    public class ValidationResponse : Response
    {
        public ValidationResponse(string failReasonCode = null) : base(failReasonCode) { }

        public static ValidationResponse Validated()
        {
            return new ValidationResponse();
        }
    }

    public class AuthorizationResponse : Response
    {
        public AuthorizationResponse(string failReasonCode = null, string parameter = null) : base(failReasonCode)
        {
            Parameter = parameter;
        }

        public string Parameter { get; }

        public static AuthorizationResponse Authorized()
        {
            return new AuthorizationResponse();
        }

        public override string ToString()
        {
            if (string.IsNullOrWhiteSpace(Parameter))
                return base.ToString();

            return $"{Parameter}-{FailReasonCode}";
        }
    }

    public class SigninCredentials
    {
        public string Username { get; set; }

        public string Password { get; set; }

        public string Preference { get; set; }

        public string Code { get; set; }

        public string ReturnUrl { get; set; }

        public string Application { get; set; }

        public bool SessionResume { get; set; }
    }

    public class SignInResponse
    {
        public string Status { get; set; }

        public string ReturnUrl { get; set; }

        public bool RequiresTwoFactorAuthentication { get; set; }

        public string[] ConfiguredTwoFactorAuthModes { get; set; }
    }

    public class SignInOptions
    {
        public bool ShowForms { get; set; }

        public bool ShowWindows { get; set; }

        public bool ShowSso { get; set; }

        public bool ShowAdfs { get; set; }

        public bool FirmConsentedToUserStatistics { get; set; }

        public CookieConsentFlags CookieConsent { get; set; }
    }
}