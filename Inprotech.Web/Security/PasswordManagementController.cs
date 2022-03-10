using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security
{
    public interface IPasswordManagementController
    {
        Task<PasswordManagementResponse> UpdateUserPassword(PasswordManagementRequest request);
    }

    [Authorize]
    [RoutePrefix("api/passwordManagement")]
    public class PasswordManagementController : ApiController, IPasswordManagementController
    {
        readonly IUserValidation _userValidation;
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISecurityContext _currentUser;
        readonly ILogger<PasswordManagementController> _logger;
        readonly IPasswordPolicy _passwordPolicy;
        readonly IPasswordVerifier _passwordVerifier;

        public PasswordManagementController(IUserValidation userValidation,
                                            IDbContext dbContext,
                                            ITaskSecurityProvider taskSecurityProvider,
                                            ISecurityContext currentUser,
                                            ILogger<PasswordManagementController> logger, 
                                            IPasswordPolicy passwordPolicy, 
                                            IPasswordVerifier passwordVerifier)
        {
            _userValidation = userValidation;
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _currentUser = currentUser;
            _logger = logger;
            _passwordPolicy = passwordPolicy;
            _passwordVerifier = passwordVerifier;
        }

        [HttpPost]
        [NoEnrichment]
        [Route("updateUserPassword")]
        public async Task<PasswordManagementResponse> UpdateUserPassword(PasswordManagementRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var user = request.IdentityKey.HasValue ? _dbContext.Set<User>().Single(u => u.Id == request.IdentityKey.Value) :
                _dbContext.Set<User>().Single(u => u.Id == _currentUser.User.Id);

            if (_currentUser.User == null && request.IdentityKey.HasValue)
            {
                if (!_taskSecurityProvider.UserHasAccessTo(request.IdentityKey.Value, ApplicationTask.ChangeMyPassword))
                {
                    _logger.Warning("The user is not authorized to change password", new
                    {
                        Urls = Request?.RequestUri,
                        UserId = request.IdentityKey
                    });
                    return new PasswordManagementResponse(PasswordManagementStatus.NotPermitted);
                }
            }
            else
            {
                if ((request.IdentityKey != null && _currentUser.User.Id == request.IdentityKey.Value) || !request.IdentityKey.HasValue)
                {
                    // change own password

                    if (string.IsNullOrEmpty(request.OldPassword))
                        return new PasswordManagementResponse(PasswordManagementStatus.OldPasswordNotProvided);

                    if (!_taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword))
                    {
                        _logger.Warning("The user is not authorized to change password", new
                        {
                            Urls = Request?.RequestUri,
                            LoggedInUserId = _currentUser.User?.Id,
                            UserId = _currentUser.User.Id
                        });
                        return new PasswordManagementResponse(PasswordManagementStatus.NotPermitted);
                    }
                }
                else
                {
                    // change somebody's password

                    if (!_taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeUserPassword) ||
                        _currentUser.User.IsExternalUser && !_currentUser.User.AccessAccount.Equals(user.AccessAccount))
                    {
                        _logger.Warning("The user is not authorized to change other users password", new
                        {
                            Urls = Request?.RequestUri,
                            LoggedInUserId = _currentUser.User.Id,
                            UserId = request.IdentityKey
                        });
                        return new PasswordManagementResponse(PasswordManagementStatus.NotPermitted);
                    }
                }
            }

            if (string.IsNullOrEmpty(request.NewPassword))
                return new PasswordManagementResponse(PasswordManagementStatus.NewPasswordNotProvided);

            if (request.NewPassword != request.ConfirmNewPassword)
                return new PasswordManagementResponse(PasswordManagementStatus.NewPasswordsDoNotMatch);

            if (!string.IsNullOrEmpty(request.OldPassword))
            {
                var validation = await _userValidation.Validate(user, request.OldPassword);
                if (!validation.Accepted) return new PasswordManagementResponse(PasswordManagementStatus.OldPasswordNotCorrect);
            }

            if (_passwordPolicy.ShouldEnforcePasswordPolicy)
            {
                var passwordPolicyEnforceStatus = _passwordPolicy.EnsureValid(request.NewPassword, user);
                if (passwordPolicyEnforceStatus.Status != PasswordManagementStatus.Success)
                {
                    return passwordPolicyEnforceStatus;
                }
            }
            _passwordVerifier.UpdateUserPassword(request.NewPassword, user);
           
            return new PasswordManagementResponse(PasswordManagementStatus.Success);
        }
    }

    public class PasswordManagementRequest
    {
        public bool IsApps { get; set; }
        public int? IdentityKey { get; set; }
        public string OldPassword { get; set; }
        public string NewPassword { get; set; }
        public string ConfirmNewPassword { get; set; }
    }

    public class PasswordManagementResponse
    {
        public PasswordManagementResponse(PasswordManagementStatus status)
        {
            Status = status;
        }

        public PasswordManagementStatus Status { get; set; }

        public string PasswordPolicyValidationErrorMessage { get; set; }

        public bool HasPasswordReused { get; set; }
    }

    public enum PasswordManagementStatus
    {
        Undefined = 0,
        NewPasswordNotProvided = 1,
        NewPasswordsDoNotMatch = 2,
        OldPasswordNotProvided = 3,
        OldPasswordNotCorrect = 4,
        NotPermitted = 5,
        Success = 6,
        PasswordPolicyValidationFailed = 7
    }
}
