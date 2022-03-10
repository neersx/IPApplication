using System;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Security;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace Inprotech.Web.Security
{
    public interface IPasswordPolicy
    {
        bool ShouldEnforcePasswordPolicy { get; }

        int PasswordUsedHistory { get; }

        PasswordManagementResponse EnsureValid(string input, User user);
    }

    public class PasswordPolicy : IPasswordPolicy
    {
        public const string PasswordRegEx = @"(?=.*[@#!_$%&])(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}";

        readonly ISiteControlReader _siteControl;
        readonly IStaticTranslator _staticTranslator;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ILogger<PasswordPolicy> _logger;
        readonly IPasswordVerifier _passwordVerifier;

        public PasswordPolicy(ISiteControlReader siteControl, IStaticTranslator staticTranslator, IPreferredCultureResolver preferredCultureResolver, ILogger<PasswordPolicy> logger, IPasswordVerifier passwordVerifier)
        {
            _siteControl = siteControl;
            _staticTranslator = staticTranslator;
            _preferredCultureResolver = preferredCultureResolver;
            _logger = logger;
            _passwordVerifier = passwordVerifier;
        }

        public bool ShouldEnforcePasswordPolicy => _siteControl.Read<bool>(SiteControls.EnforcePasswordPolicy);

        public int PasswordUsedHistory => _siteControl.Read<int?>(SiteControls.PasswordUsedHistory) ?? 0;

        public PasswordManagementResponse EnsureValid(string enteredPassword, User user)
        {
            if (!ShouldEnforcePasswordPolicy)
                return new PasswordManagementResponse(PasswordManagementStatus.Success);

            if (StringComparer.OrdinalIgnoreCase.Compare(user.UserName, enteredPassword) == 0 || enteredPassword.ToLower().Contains(user.UserName.ToLower()))
            {
                return LogResponse(user.Id, "Username should not be same as password");
            }

            var passwordValidator = new Regex(PasswordRegEx);
            if (!passwordValidator.IsMatch(enteredPassword))
            {
                return LogResponse(user.Id, "password regex failed");
            }

            if (_passwordVerifier.HasPasswordReused(enteredPassword, user.PasswordHistory))
            {
                var response = LogResponse(user.Id, "password already used");
                response.HasPasswordReused = true;
                response.PasswordPolicyValidationErrorMessage = ErrorMessageForInprotech(true);
                return response;
            }

            return new PasswordManagementResponse(PasswordManagementStatus.Success);
        }

        PasswordManagementResponse LogResponse(int id, string message)
        {
            _logger.Warning("Password Policy Validation Failed: " + message, new
            {
                LoggedInUserId = id,
                UserId = id
            });
            return new PasswordManagementResponse(PasswordManagementStatus.PasswordPolicyValidationFailed)
            {
                PasswordPolicyValidationErrorMessage = ErrorMessageForInprotech()
            };
        }

        public string ErrorMessageForInprotech(bool hasReusedPasswords = false)
        {
            var culture = _preferredCultureResolver.ResolveAll().ToArray();
            if (hasReusedPasswords)
            {
                return PasswordUsedHistory == 1 ? string.Format(_staticTranslator.TranslateWithDefault("signin.passwordPolicyContentShouldNotSameAsUsedPasswordOne", culture)) : string.Format(_staticTranslator.TranslateWithDefault("signin.passwordPolicyContentShouldNotSameAsUsedPassword", culture), PasswordUsedHistory);
            }
            var message = new StringBuilder(_staticTranslator.TranslateWithDefault("signin.passwordPolicy-heading", culture));
            message.AppendLine("<ul style=\"margin-top: 0px; margin-left:-25px\">");
            message.AppendFormat("{0}{1}{2}","<li>",_staticTranslator.TranslateWithDefault("signin.passwordPolicyContentAtLeastEightCharacters", culture),"</li>");
            message.AppendFormat("{0}{1}{2}","<li>",_staticTranslator.TranslateWithDefault("signin.passwordPolicyContentAtLeastOneSpecialCharacter", culture),"</li>");
            message.AppendFormat("{0}{1}{2}","<li>",_staticTranslator.TranslateWithDefault("signin.passwordPolicyContentAtLeastOneUpperAndLowerCase", culture),"</li>");
            message.AppendFormat("{0}{1}{2}","<li>",_staticTranslator.TranslateWithDefault("signin.passwordPolicyContentAtLeastOneNumericValue", culture),"</li>");
            message.AppendLine("</ul>");
            return message.ToString();
        }
       
    }
}
