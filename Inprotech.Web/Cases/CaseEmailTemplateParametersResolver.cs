using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases
{
    public interface ICaseEmailTemplateParametersResolver
    {
        Task<CaseNameEmailTemplateParameters[]> Resolve(CaseNameEmailTemplateParameters parameters);
    }

    public class CaseEmailTemplateParametersResolver : ICaseEmailTemplateParametersResolver
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IEmailValidator _emailValidator;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseEmailTemplateParametersResolver(IDbContext dbContext,
                                                   ISecurityContext securityContext,
                                                   ITaskSecurityProvider taskSecurityProvider,
                                                   IEmailValidator emailValidator,
                                                   Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _taskSecurityProvider = taskSecurityProvider;
            _emailValidator = emailValidator;
            _clock = clock;
        }

        public async Task<CaseNameEmailTemplateParameters[]> Resolve(CaseNameEmailTemplateParameters parameters)
        {
            if (parameters == null) throw new ArgumentNullException(nameof(parameters));

            var now = _clock().Date;
            var task = _securityContext.User.IsExternalUser
                ? ApplicationTask.EmailOurCaseContact
                : ApplicationTask.EmailCaseResponsibleStaff;

            if (!_taskSecurityProvider.HasAccessTo(task)) return new CaseNameEmailTemplateParameters[0];

            var interim = await (from cn in _dbContext.Set<CaseName>()
                                 join n in _dbContext.Set<Name>() on cn.NameId equals n.Id into n1
                                 from n in n1
                                 join t in _dbContext.Set<Telecommunication>() on n.MainEmailId equals t.Id into t1
                                 from t in t1
                                 where (parameters.Sequence == null || cn.Sequence == parameters.Sequence)
                                       && cn.CaseId == parameters.CaseKey
                                       && cn.NameTypeId == parameters.NameType
                                       && (cn.ExpiryDate != null && cn.ExpiryDate > now || cn.ExpiryDate == null)
                                       && t != null
                                 select new CaseNameEmailTemplateParameters
                                 {
                                     CaseKey = cn.CaseId,
                                     NameType = cn.NameTypeId,
                                     Sequence = cn.Sequence,
                                     CaseNameMainEmail = t.TelecomNumber
                                 }).ToArrayAsync();

            return (from i in interim
                    where !string.IsNullOrWhiteSpace(i.CaseNameMainEmail) && _emailValidator.IsValid(i.CaseNameMainEmail)
                    select i).ToArray();
        }
    }
}