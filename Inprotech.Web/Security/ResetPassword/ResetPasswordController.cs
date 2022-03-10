using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security.ResetPassword
{
    [RoutePrefix(Urls.ResetPassword)]
    public class ResetPasswordController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ICryptoService _cryptoService;
        readonly ISiteControlReader _siteControls;
        readonly IUserAuditLogger<ResetPasswordController> _logger;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IResetPasswordHelper _resetPasswordHelper;
        readonly IPasswordManagementController _passwordManagementController;
        readonly Func<DateTime> _now;
        readonly IUserValidation _userValidation;

        public ResetPasswordController(IDbContext dbContext, ICryptoService cryptoService, ISiteControlReader siteControls,
                                       ITaskSecurityProvider taskSecurityProvider,
                                       IUserAuditLogger<ResetPasswordController> logger,
                                       IResetPasswordHelper resetPasswordHelper, IPasswordManagementController passwordManagementController, Func<DateTime> now,
                                       IUserValidation userValidation)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _siteControls = siteControls;
            _taskSecurityProvider = taskSecurityProvider;
            _logger = logger;
            _resetPasswordHelper = resetPasswordHelper;
            _passwordManagementController = passwordManagementController;
            _now = now;
            _userValidation = userValidation;
        }

        [HttpPost]
        [NoEnrichment]
        [Route("sendlink")]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Forms)]
        public async Task<HttpResponseMessage> SendLink(SendLinkRequest request)
        {
            if (string.IsNullOrEmpty(request.Username)) throw new ArgumentNullException(nameof(request));

            var user = _dbContext.Set<User>().SingleOrDefault(u => u.UserName == request.Username);
            if (user != null)
            {
                await _resetPasswordHelper.SendResetEmail(user, request.Url);
            }
            else
            {
                _logger.Warning("Username provided is not valid", Request);
            }

            return Request.CreateResponse(HttpStatusCode.OK, new { Status = "success" });
        }

        [HttpPost]
        [NoEnrichment]
        [Route("")]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Forms)]
        public async Task<HttpResponseMessage> VerifyLink([FromBody] ResetPasswordRequest resetPasswordRequest)
        {
            if (resetPasswordRequest == null) throw new ArgumentNullException(nameof(resetPasswordRequest));

            var configuredKey = _cryptoService.Decrypt(resetPasswordRequest.Token);
            if (string.IsNullOrWhiteSpace(configuredKey))
            {
                return LogResponse(null, "Incorrect token passed", ResetPasswordStatus.IncorrectToken);
            }

            var setting = await _dbContext.Set<SettingValues>()
                                                .Where(
                                                       s => s.SettingId == KnownSettingIds.ResetPasswordSecretKey &&
                                                            s.CharacterValue == configuredKey)
                                                .FirstOrDefaultAsync();

            if (setting == null)
            {
                return LogResponse(null, "Incorrect token passed", ResetPasswordStatus.IncorrectToken);
            }

            var user = setting.User;

            if (user == null)
            {
                return LogResponse(null, "Not a valid user", ResetPasswordStatus.UserInvalid);
            }

            if (resetPasswordRequest.IsPasswordExpired)
            {
                if (string.IsNullOrEmpty(resetPasswordRequest.OldPassword))
                    return LogResponse(user.UserName, "Old password is mandatory to change expired password", ResetPasswordStatus.Unauthorized);

                var validation = await _userValidation.Validate(user, resetPasswordRequest.OldPassword);
                if (!validation.Accepted)
                    return Request.CreateResponse(HttpStatusCode.OK, new { Status = ResetPasswordStatus.OldPasswordNotCorrect });
            }

            if (!_taskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword))
            {
                return LogResponse(user.UserName, "The user is not authorized to change password", ResetPasswordStatus.Unauthorized);
            }

            if (user.IsLocked)
            {
                return LogResponse(user.UserName, "User account locked", ResetPasswordStatus.UserLocked);
            }

            var name = _dbContext.Set<User>()
                                 .Include(_ => _.Name.Telecoms)
                                 .Single(_ => _.Id == user.Id)
                                 .Name;
            var email = name.MainEmailAddress();
            if (string.IsNullOrWhiteSpace(email))
            {
                return LogResponse(user.UserName, "User email not valid", ResetPasswordStatus.UserEmailNotProvided);
            }

            var logTimeOffset = _siteControls.Read<int?>(SiteControls.LogTimeOffset);
            var currentTime = _now().Add(TimeSpan.FromMinutes(logTimeOffset ?? 0));

            if (currentTime - setting.TimeStamp > TimeSpan.FromMinutes(30))
            {
                return LogResponse(user.UserName, "User reset password request has expired", ResetPasswordStatus.RequestExpired);
            }

            var response = _passwordManagementController.UpdateUserPassword(new PasswordManagementRequest()
            {
                IdentityKey = user.Id,
                NewPassword = resetPasswordRequest.NewPassword,
                ConfirmNewPassword = resetPasswordRequest.ConfirmPassword
            });

            switch (response.Result.Status)
            {
                case PasswordManagementStatus.PasswordPolicyValidationFailed:
                    return Request.CreateResponse(HttpStatusCode.OK, new { Status = ResetPasswordStatus.PasswordPolicyValidationFailed, response.Result.HasPasswordReused, response.Result.PasswordPolicyValidationErrorMessage });
                case PasswordManagementStatus.Success:
                    _dbContext.Set<SettingValues>().Remove(setting);
                    await _dbContext.SaveChangesAsync();

                    return Request.CreateResponse(HttpStatusCode.OK, new { Status = ResetPasswordStatus.Success });
            }

            return LogResponse(user.UserName, response.Result.Status.ToString(), ResetPasswordStatus.PasswordNotUpdated);
        }

        HttpResponseMessage LogResponse(string userName, string message, ResetPasswordStatus status)
        {
            _logger.Warning(userName + " | " + message + " | " + status, Request);

            return Request.CreateResponse(HttpStatusCode.BadRequest, new { Status = status });
        }

        public enum ResetPasswordStatus
        {
            IncorrectToken = 0,
            UserLocked = 1,
            UserInvalid = 2,
            UserEmailNotProvided = 3,
            RequestExpired = 4,
            Unauthorized = 5,
            PasswordNotUpdated = 6,
            Success = 7,
            PasswordPolicyValidationFailed = 8,
            OldPasswordNotCorrect = 9
        }

        public class ResetPasswordRequest
        {
            public string Token { get; set; }
            public string NewPassword { get; set; }
            public string ConfirmPassword { get; set; }
            public string OldPassword { get; set; }
            public bool IsPasswordExpired { get; set; }
        }

        public class SendLinkRequest
        {
            public string Username { get; set; }
            public string Url { get; set; }
        }
    }
}