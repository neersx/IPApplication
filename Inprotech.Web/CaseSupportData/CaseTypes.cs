using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.CaseSupportData
{
    public interface ICaseTypes
    {
        IEnumerable<KeyValuePair<string, string>> Get();

        CaseType GetCaseType(int caseTypeId);

        IEnumerable<KeyValuePair<string, string>> IncludeDraftCaseTypes();

        IEnumerable<CaseType> GetCaseTypesWithDetails();
    }

    public class CaseTypes : ICaseTypes
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public CaseTypes(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _securityContext = securityContext ?? throw new ArgumentNullException(nameof(securityContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
        }

        public IEnumerable<KeyValuePair<string, string>> Get()
        {
            return _dbContext.GetCaseTypes(
                                           _securityContext.User.Id,
                                           _preferredCultureResolver.Resolve(),
                                           _securityContext.User.IsExternalUser)
                             .Select(a => new KeyValuePair<string, string>(a.CaseTypeKey, a.CaseTypeDescription));
        }

        public CaseType GetCaseType(int caseTypeId)
        {
            var caseType = _dbContext.Set<EntityModel.CaseType>()
                                     .SingleOrDefault(_ => _.Id == caseTypeId);
            if (caseType == null)
            {
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.CaseTypeDoesNotExist.ToString());
            }

            return new CaseType(caseType.Code, caseType.Name) {ActualCaseType = caseType.ActualCaseTypeId != null ? new CaseType(caseType.ActualCaseType.Code, caseType.ActualCaseType.Name) : null};
        }

        public IEnumerable<KeyValuePair<string, string>> IncludeDraftCaseTypes()
        {
            var caseTypes = Get().ToArray();
            if (_securityContext.User.IsExternalUser)
                return caseTypes;
            
            var draftCaseTypes = _dbContext.Set<EntityModel.CaseType>()
                                           .Where(_ => !string.IsNullOrEmpty(_.ActualCaseTypeId)).ToArray()
                                           .Select(a => new KeyValuePair<string, string>(a.Code, a.Name));

            return caseTypes.Union(draftCaseTypes);
        }

        public IEnumerable<CaseType> GetCaseTypesWithDetails()
        {
            var caseTypeIds = IncludeDraftCaseTypes().Select(_ => _.Key).ToArray();
            return _dbContext.Set<EntityModel.CaseType>()
                             .Where(_ => caseTypeIds.Contains(_.Code)).ToArray()
                             .Select(_ => new CaseType
                                          {
                                              Key = _.Id,
                                              Code = _.Code,
                                              Value = _.Name,
                                              ActualCaseType = _.ActualCaseType != null ? new CaseType(_.ActualCaseType.Code, _.ActualCaseType.Name) : null
                                          }).ToArray();
        }
    }
}