using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    public class ClientAccessDetails
    {
        public Name ExternalContact { get; set; }
        public string Reference { get; set; }
        public Name FirmContact { get; set; }
        public string FirmContactNameType { get; set; }
        public string FirmContactNameTypeShowCode { get; set; }
    }

    public interface IClientNameDetails
    {
        ClientAccessDetails GetDetails(Case @case);
    }

    public class ClientNameDetails : IClientNameDetails
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControls;

        public ClientNameDetails(IDbContext dbContext, ISecurityContext securityContext, ISiteControlReader siteControls)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _siteControls = siteControls;
        }

        public ClientAccessDetails GetDetails(Case @case)
        {
            var caseAccess = (from v in _dbContext.FilterUserCases(_securityContext.User.Id, true, @case.Id)
                           join q in _dbContext.Set<Name>() on v.ClientCorrespondName equals q.Id into qs
                           from q in qs.DefaultIfEmpty()
                           join l in _dbContext.Set<Name>() on v.ClientMainContact equals l.Id into ls
                           from l in ls.DefaultIfEmpty()
                           select new 
                                  {
                                      CorrName = q,
                                      MainContact = l,
                                      Reference = v.ClientReferenceNo
                                  }).SingleOrDefault();

            var firmContact = CaseContact(@case);

            return new ClientAccessDetails
                   {
                       ExternalContact = caseAccess?.CorrName ?? caseAccess?.MainContact,
                       Reference = caseAccess?.Reference,
                       FirmContact = firmContact.Name,
                       FirmContactNameType = firmContact.NameTypeId,
                       FirmContactNameTypeShowCode = firmContact.ShowCode
                   };
        }

        (Name Name, string NameTypeId, string ShowCode) CaseContact(Case @case)
        {
            CaseName contact = null;
            var contactNameType = _siteControls.Read<string>(SiteControls.WorkBenchContactNameType);

            if (!string.IsNullOrWhiteSpace(contactNameType))
            {
                contact = @case.CaseNames.SingleOrDefault(_ => _.NameTypeId == contactNameType);
            }

            if (contact == null)
            {
                contact = @case.CaseNames.FirstOrDefault(_ => _.NameTypeId == KnownNameTypes.Signatory) ?? 
                          @case.CaseNames.FirstOrDefault(_ => _.NameTypeId == KnownNameTypes.StaffMember);
            }

            return (contact?.Name, contact?.NameTypeId, contact?.NameType?.ToShowNameCode());
        }
    }
}